import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import Testing
@testable import WatermarkCore

struct RelativeWatermarkTests {
    let a4 = CGSize(width: 210 / 25.4 * 72, height: 297 / 25.4 * 72)

    // Fixtures are generated from an empty synthetic document; no personal data.
    func fixture(_ root: URL, format: OutputFormat, multiplier: CGFloat) throws -> SourceDocument {
        let url = root.appendingPathComponent("equivalent-\(multiplier).\(format.fileExtension)")
        if format == .pdf {
            var box = CGRect(origin: .zero, size: a4)
            let context = try #require(CGContext(url as CFURL, mediaBox: &box, nil))
            context.beginPDFPage(nil); context.endPDFPage(); context.closePDF()
        } else {
            let context = try Renderer.bitmap(size: CGSize(width: a4.width * multiplier, height: a4.height * multiplier))
            try Renderer.encoded(try #require(context.makeImage()), format: format).write(to: url)
        }
        return try SourceDocument.load(url)
    }

    func normalizedPixels(size: CGSize, settings: WatermarkSettings) throws -> Data {
        let context = try Renderer.bitmap(size: a4)
        context.scaleBy(x: a4.width / size.width, y: a4.height / size.height)
        Renderer.watermark(context, size: size, settings: settings, raster: true)
        return Data(bytes: context.data!, count: context.bytesPerRow * context.height)
    }

    @Test func wholePatternIsResolutionIndependent() throws {
        for direction in WatermarkDirection.allCases {
            for (size, spacing) in [(12.0, 50.0), (36, 150), (72, 300)] {
                var mark = WatermarkSettings(); mark.color = .black; mark.direction = direction
                mark.size = size; mark.spacing = spacing
                let baseline = try normalizedPixels(size: a4, settings: mark)
                for factor: CGFloat in [0.5, 2, 8] {
                    #expect(try normalizedPixels(size: CGSize(width: a4.width * factor, height: a4.height * factor), settings: mark) == baseline)
                }
                var empty = mark; empty.text = ""
                var invisible = mark; invisible.opacity = 0
                #expect(try normalizedPixels(size: a4, settings: empty) == normalizedPixels(size: a4, settings: invisible))
            }
        }
    }

    @Test func equivalentSourceFormats() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var mark = WatermarkSettings(); mark.color = .black; mark.opacity = 100
        var output = ExportSettings(); output.flattened = false
        var coverage: [Double] = []
        for format in OutputFormat.allCases {
            for multiplier: CGFloat in [1, 3] {
                let source = try fixture(root, format: format, multiplier: multiplier)
                let size = try PreviewRendering.pageSize(source, pageIndex: 0)
                let data = try PreviewRendering.render(source, pageIndex: 0, watermark: mark, export: output,
                    viewport: PreviewViewport(region: CGRect(origin: .zero, size: size), scale: a4.width / size.width))
                let image = try ViewportTests().decode(data)
                let bytes = try ViewportTests().pixels(image)
                let dark = bytes.enumerated().filter { $0.offset % 4 == 0 && $0.element < 128 }.count
                coverage.append(Double(dark) / Double(image.width * image.height))
            }
        }
        #expect(try #require(coverage.max()) - #require(coverage.min()) < 0.003)
        #expect(try #require(coverage.min()) > 0.01)
    }
    @Test func reopenedRoutesMatchRegionsAndKeepGeometry() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for file in ["document.pdf", "opaque.png", "photo.jpg"] {
            let source = try SourceDocument.load(Bundle.module.url(forResource: file, withExtension: nil, subdirectory: "Fixtures")!)
            for format in OutputFormat.allCases {
                for dpi in source.kind == .pdf ? [300, 450, 600] : [450] {
                    for flattened in source.kind == .pdf ? [false, true] : [false] {
                        var output = ExportSettings(); output.format = format; output.dpi = dpi; output.flattened = flattened
                        var mark = WatermarkSettings(); mark.color = .black; mark.opacity = 50
                        mark.direction = dpi == 450 ? .descending : .ascending
                        let directory = root.appendingPathComponent(UUID().uuidString)
                        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                        let target = source.kind == .pdf && format != .pdf ? directory : directory.appendingPathComponent("saved.\(format.fileExtension)")
                        let urls = try Processing.export(source, watermark: mark, settings: output, destination: target)
                        for page in 0..<source.pageCount {
                            let size = try PreviewRendering.pageSize(source, pageIndex: page)
                            let saved: CGImage
                            if format == .pdf {
                                let pdf = try #require(PDFDocument(url: urls[0]))
                                let reopened = try #require(pdf.page(at: page))
                                #expect(Renderer.pageSize(reopened) == size)
                                if source.kind == .pdf {
                                    #expect((pdf.string?.contains("COPY") == true) == !flattened)
                                }
                                var empty = mark; empty.text = ""
                                saved = try Renderer.renderPage(reopened, settings: empty, scale: 1, raster: false)
                            } else {
                                saved = try ViewportTests().decode(Data(contentsOf: urls[source.kind == .pdf ? page : 0]))
                            }
                            #expect(saved.width == Int(ceil(size.width)) && saved.height == Int(ceil(size.height)))
                            let region = CGRect(x: 40, y: 30, width: 160, height: 120)
                            let crop = try #require(saved.cropping(to: CGRect(x: region.minX, y: size.height - region.maxY, width: region.width, height: region.height)))
                            let preview = try ViewportTests().decode(PreviewRendering.render(source, pageIndex: page,
                                watermark: mark, export: output, viewport: PreviewViewport(region: region, scale: 1, detailed: true)))
                            let a = try ViewportTests().pixels(crop), b = try ViewportTests().pixels(preview)
                            #expect(a.count == b.count)
                            let error = zip(a, b).reduce(0.0) { $0 + abs(Double($1.0) - Double($1.1)) } / Double(a.count)
                            #expect(error < 8, "\(file) \(format) \(dpi) flat=\(flattened) page=\(page): \(error)")
                        }
                    }
                }
            }
        }
    }

}
