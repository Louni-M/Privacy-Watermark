import Foundation
import CoreGraphics
import PDFKit

public enum Processing {
    public static func preview(_ source: SourceDocument, watermark: WatermarkSettings, export: ExportSettings, maximumDimension: CGFloat = 1200) throws -> Data {
        try watermark.validate()
        try export.validate()
        let image: CGImage
        if source.kind == .image {
            image = try Renderer.renderImage(source, settings: watermark, maxDimension: maximumDimension)
        } else {
            guard let doc = PDFDocument(data: source.data), let page = doc.page(at: 0) else { throw DocumentError.invalidPDF }
            let size = Renderer.pageSize(page)
            image = try Renderer.renderPage(page, settings: watermark,
                scale: min(2, maximumDimension / max(size.width, size.height)), raster: export.flattened)
        }
        return try Renderer.encoded(image, format: .png)
    }

    public static func destinations(for source: SourceDocument, export: ExportSettings, destination: URL) -> [URL] {
        if source.kind == .pdf && export.format != .pdf {
            let stem = source.url.deletingPathExtension().lastPathComponent
            return (1...source.pageCount).map {
                destination.appendingPathComponent(String(format: "%@_page_%03d.%@", stem, $0, export.format.fileExtension))
            }
        }
        return [destination]
    }

    /// Rendering and commit are separate so a failed page never leaves half an export.
    @discardableResult public static func export(_ source: SourceDocument, watermark: WatermarkSettings, settings: ExportSettings,
                              destination: URL, replaceExisting: Bool = false) throws -> [URL] {
        try watermark.validate()
        try settings.validate()
        let outputs = destinations(for: source, export: settings, destination: destination)
        let transaction = try OutputTransaction(source: source.url, outputs: outputs, replaceExisting: replaceExisting)
        defer { transaction.cleanUp() }
        if source.kind == .image {
            let image = try Renderer.renderImage(source, settings: watermark)
            if settings.format == .pdf {
                try ImagePDFWriter.write(to: transaction.staged[0], pageCount: 1) { _ in
                    let size = CGSize(width: image.width, height: image.height)
                    return ImagePDFWriter.Page(jpeg: try Renderer.encoded(image, format: .jpg, quality: 0.9), pixels: size, size: size)
                }
            } else {
                try Renderer.encoded(image, format: settings.format).write(to: transaction.staged[0])
            }
        } else {
            guard let document = PDFDocument(data: source.data) else { throw DocumentError.invalidPDF }
            if settings.format == .pdf && settings.flattened {
                try ImagePDFWriter.write(to: transaction.staged[0], pageCount: document.pageCount) { index in
                    guard let page = document.page(at: index) else { throw DocumentError.invalidPDF }
                    let image = try Renderer.renderPage(page, settings: watermark, scale: CGFloat(settings.dpi) / 72, raster: true)
                    return ImagePDFWriter.Page(jpeg: try Renderer.encoded(image, format: .jpg, quality: 0.95),
                        pixels: CGSize(width: image.width, height: image.height), size: Renderer.pageSize(page))
                }
            } else if settings.format == .pdf {
                try writePDF(to: transaction.staged[0]) { context in
                    for index in 0..<document.pageCount {
                        try Task.checkCancellation()
                        try autoreleasepool {
                            guard let page = document.page(at: index) else { throw DocumentError.invalidPDF }
                            let size = Renderer.pageSize(page)
                            beginPage(context, size: size)
                            context.saveGState()
                            page.draw(with: .cropBox, to: context)
                            context.restoreGState()
                            Renderer.watermark(context, size: size, settings: watermark, raster: false)
                            preserveLinks(page, index: index, document: document, context: context)
                            context.endPDFPage()
                        }
                    }
                }
            } else {
                for index in 0..<document.pageCount {
                    try Task.checkCancellation()
                    try autoreleasepool {
                        guard let page = document.page(at: index) else { throw DocumentError.invalidPDF }
                        let image: CGImage
                        if settings.flattened {
                            let highResolution = try Renderer.renderPage(page, settings: watermark,
                                scale: CGFloat(settings.dpi) / 72, raster: true)
                            let size = Renderer.pageSize(page)
                            let compressed = try Renderer.jpegImage(highResolution, quality: 0.95,
                                maximumDimension: max(size.width, size.height))
                            let downsample = try Renderer.bitmap(size: size)
                            downsample.draw(compressed, in: CGRect(origin: .zero, size: size))
                            guard let result = downsample.makeImage() else { throw DocumentError.renderFailed }
                            image = result
                        } else {
                            image = try Renderer.renderPage(page, settings: watermark, scale: 1, raster: false)
                        }
                        try Renderer.encoded(image, format: settings.format).write(to: transaction.staged[index])
                    }
                }
            }
        }
        try Task.checkCancellation()
        try transaction.commit()
        return outputs
    }

    private static func beginPage(_ context: CGContext, size: CGSize) {
        var box = CGRect(origin: .zero, size: size)
        let data = Data(bytes: &box, count: MemoryLayout<CGRect>.size)
        context.beginPDFPage([kCGPDFContextMediaBox as String: data] as CFDictionary)
    }

    private static func preserveLinks(_ page: PDFPage, index: Int, document: PDFDocument, context: CGContext) {
        context.addDestination("page-\(index)" as CFString, at: CGPoint(x: 0, y: Renderer.pageSize(page).height))
        for annotation in page.annotations {
            let rect = annotation.bounds.applying(page.transform(for: .cropBox))
            if let action = annotation.action as? PDFActionURL, let url = action.url {
                context.setURL(url as CFURL, for: rect)
            } else if let action = annotation.action as? PDFActionGoTo, let destinationPage = action.destination.page {
                let target = document.index(for: destinationPage)
                if target != NSNotFound { context.setDestination("page-\(target)" as CFString, for: rect) }
            }
        }
    }

    private static func writePDF(to url: URL, draw: (CGContext) throws -> Void) throws {
        let sink = try PDFSink(url: url)
        defer { try? sink.handle.close() }
        var callbacks = CGDataConsumerCallbacks(putBytes: { info, bytes, count in
            guard let info else { return 0 }
            let sink = Unmanaged<PDFSink>.fromOpaque(info).takeUnretainedValue()
            do {
                try sink.append(bytes, count: count)
                return count
            } catch { sink.failed = true; return 0 }
        }, releaseConsumer: nil)
        guard let consumer = CGDataConsumer(info: Unmanaged.passUnretained(sink).toOpaque(), cbks: &callbacks),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { throw DocumentError.writeFailed }
        do { try draw(context) } catch { context.closePDF(); throw error }
        context.closePDF()
        try sink.flush()
        guard !sink.failed else { throw DocumentError.writeFailed }
    }
}

private final class PDFSink {
    let handle: FileHandle
    var failed = false
    private var buffer = Data()
    init(url: URL) throws {
        guard FileManager.default.createFile(atPath: url.path, contents: nil,
            attributes: [.posixPermissions: 0o600]) else { throw DocumentError.writeFailed }
        handle = try FileHandle(forWritingTo: url)
    }
    func append(_ bytes: UnsafeRawPointer, count: Int) throws {
        buffer.append(bytes.assumingMemoryBound(to: UInt8.self), count: count)
        if buffer.count >= 256 * 1024 { try flush() }
    }
    func flush() throws {
        guard !buffer.isEmpty else { return }
        try handle.write(contentsOf: buffer)
        buffer.removeAll(keepingCapacity: true)
    }
}
