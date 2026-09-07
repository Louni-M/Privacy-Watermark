import Foundation
import CoreGraphics
import PDFKit
import ImageIO
import Testing
@testable import WatermarkCore

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["PASSPORT_VISUAL_OUTPUT"] != nil))
struct VisualReviewTests {
    @Test func recordSavedFitAndZoomComparisons() throws {
        let root = URL(fileURLWithPath: ProcessInfo.processInfo.environment["PASSPORT_VISUAL_OUTPUT"]!)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var records: [[String: Any]] = []
        for file in ["document.pdf", "pages-10.pdf", "transparent.png"] {
            let source = try SourceDocument.load(Bundle.module.url(forResource: file, withExtension: nil, subdirectory: "Fixtures")!)
            for (mode, flattened, format) in [("standard", false, OutputFormat.pdf), ("flattened", true, .pdf), ("pages", true, .png)] {
                let folder = root.appendingPathComponent(file + "-" + mode)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                var export = ExportSettings(); export.flattened = flattened; export.format = format
                var mark = WatermarkSettings()
                mark.color = mode == "standard" ? .black : .gray
                mark.direction = mode == "flattened" ? .descending : .ascending
                var allocator = DestinationAllocator(directory: folder, sources: [source.url])
                let outputs = try BatchExport.save(source, watermark: mark, settings: export, allocator: &allocator)
                for index in Set([0, source.pageCount / 2, source.pageCount - 1]).sorted() {
                    let size = try PreviewRendering.pageSize(source, pageIndex: index)
                    let full = CGRect(origin: .zero, size: size)
                    let pan = CGRect(x: floor(size.width / 4), y: floor(size.height / 4),
                        width: floor(size.width / 2), height: floor(size.height / 2))
                    var images: [CGImage] = []
                    for (label, region, scale, detailed) in [("fit", full, 1.0, false), ("zoom", pan, 2.0, true)] {
                        let bytes = try PreviewRendering.render(source, pageIndex: index, watermark: mark, export: export,
                            viewport: PreviewViewport(region: region, scale: scale, detailed: detailed))
                        try bytes.write(to: folder.appendingPathComponent("\(index)-\(label).png"))
                        let encoded = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
                        images.append(try #require(CGImageSourceCreateImageAtIndex(encoded, 0, nil)))
                    }
                    let saved: CGImage
                    if format == .pdf {
                        let document = try #require(PDFDocument(url: outputs[0]))
                        let page = try #require(document.page(at: index))
                        var none = WatermarkSettings(); none.text = ""
                        saved = try Renderer.renderPage(page, settings: none, scale: 1, raster: false)
                    } else {
                        let bytes = try Data(contentsOf: outputs[source.kind == .pdf ? index : 0])
                        let encoded = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
                        saved = try #require(CGImageSourceCreateImageAtIndex(encoded, 0, nil))
                    }
                    try Renderer.encoded(saved, format: .png).write(to: folder.appendingPathComponent("\(index)-saved.png"))
                    let sheet = try Renderer.bitmap(size: CGSize(width: 1200, height: 440))
                    for (column, image) in ([saved] + images).enumerated() {
                        let fit = min(380 / CGFloat(image.width), 400 / CGFloat(image.height))
                        sheet.draw(image, in: CGRect(x: CGFloat(column) * 400 + 10, y: 20,
                            width: CGFloat(image.width) * fit, height: CGFloat(image.height) * fit))
                    }
                    let sheetURL = folder.appendingPathComponent("\(index)-comparison.png")
                    try Renderer.encoded(try #require(sheet.makeImage()), format: .png).write(to: sheetURL)
                    records.append(["file": file, "mode": mode, "page_index": index,
                        "size": NSStringFromSize(size), "pan": NSStringFromRect(pan),
                        "sheet": sheetURL.path, "columns": ["saved", "fit preview", "zoomed/panned preview"]])
                }
            }
        }
        try JSONSerialization.data(withJSONObject: ["comparisons": records], options: [.sortedKeys, .prettyPrinted])
            .write(to: root.appendingPathComponent("visual-manifest.json"))
    }
}
