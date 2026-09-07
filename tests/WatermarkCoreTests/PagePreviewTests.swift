import Foundation
import ImageIO
import PDFKit
import Testing
@testable import WatermarkCore

struct PagePreviewTests {
    func fixture(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")!
    }

    @Test func pageBoundsAndGeometry() throws {
        for file in ["document.pdf", "pages-10.pdf", "photo.jpg"] {
            let source = try SourceDocument.load(fixture(file))
            for invalid in [-1, source.pageCount] {
                #expect(throws: DocumentError.invalidPage) {
                    try Processing.preview(source, watermark: WatermarkSettings(), export: ExportSettings(), pageIndex: invalid)
                }
            }
            for index in Set([0, source.pageCount / 2, source.pageCount - 1]) {
                let bytes = try Processing.preview(source, watermark: WatermarkSettings(), export: ExportSettings(), pageIndex: index)
                let encoded = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
                let image = try #require(CGImageSourceCreateImageAtIndex(encoded, 0, nil))
                let size = source.kind == .pdf
                    ? Renderer.pageSize(try #require(PDFDocument(data: source.data)?.page(at: index)))
                    : CGSize(width: source.pixelWidth, height: source.pixelHeight)
                #expect(abs(CGFloat(image.width) / CGFloat(image.height) - size.width / size.height) < 0.01)
            }
        }
    }

    @Test func pageImagePreviewMatchesSavedPNG() throws {
        let source = try SourceDocument.load(fixture("document.pdf"))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for flattened in [false, true] {
            var settings = OutputPolicy.png.resolve(for: source.url, settings: ExportSettings())
            settings.flattened = flattened
            let outputs = try Processing.export(source, watermark: WatermarkSettings(), settings: settings,
                destination: root, replaceExisting: true)
            for index in 0..<source.pageCount {
                let preview = try Processing.preview(source, watermark: WatermarkSettings(), export: settings, pageIndex: index)
                #expect(preview == (try Data(contentsOf: outputs[index])))
            }
        }
    }
}
