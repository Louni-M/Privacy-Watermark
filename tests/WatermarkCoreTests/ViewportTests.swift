import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import WatermarkCore

struct ViewportTests {
    func decode(_ bytes: Data) throws -> CGImage {
        let source = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
        return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    func pixels(_ image: CGImage) throws -> Data {
        let context = try Renderer.bitmap(size: CGSize(width: image.width, height: image.height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Data(bytes: context.data!, count: context.bytesPerRow * context.height)
    }

    @Test func panningPreservesDocumentOrigin() throws {
        for file in ["opaque.png", "transparent.png", "document.pdf"] {
            let source = try SourceDocument.load(Bundle.module.url(forResource: file, withExtension: nil, subdirectory: "Fixtures")!)
            for page in Set([0, source.pageCount - 1]) {
                let size = try PreviewRendering.pageSize(source, pageIndex: page)
                var settings = ExportSettings(); settings.format = .png; settings.flattened = false
                let region = CGRect(x: 48, y: 32, width: 160, height: 120)
                let whole = try decode(Processing.preview(source, watermark: WatermarkSettings(), export: settings,
                    maximumDimension: max(size.width, size.height), pageIndex: page))
                // CGImage cropping uses a top-left pixel origin.
                let crop = try #require(whole.cropping(to: CGRect(x: region.minX, y: size.height - region.maxY,
                    width: region.width, height: region.height)))
                let viewport = try decode(PreviewRendering.render(source, pageIndex: page, watermark: WatermarkSettings(),
                    export: settings, viewport: PreviewViewport(region: region, scale: 1, detailed: true)))
                #expect(try pixels(crop) == pixels(viewport))
            }
        }
    }

    @Test func fitZoomAndBufferBounds() throws {
        let source = try SourceDocument.load(Bundle.module.url(forResource: "document.pdf", withExtension: nil, subdirectory: "Fixtures")!)
        let region = CGRect(x: 40, y: 30, width: 200, height: 100)
        for format in OutputFormat.allCases {
            var settings = ExportSettings(); settings.format = format
            let image = try decode(PreviewRendering.render(source, pageIndex: 0, watermark: WatermarkSettings(), export: settings,
                viewport: PreviewViewport(region: region, scale: 4, backingScale: 2, detailed: true)))
            #expect(image.width * image.height <= PreviewRendering.maximumPixels)
            #expect(image.width == (format == .pdf ? 1250 : 200))
        }
        var standard = ExportSettings(); standard.flattened = false
        #expect(throws: DocumentError.renderFailed) {
            try PreviewRendering.render(source, pageIndex: 0, watermark: WatermarkSettings(), export: standard,
                viewport: PreviewViewport(region: region, scale: 1000))
        }
    }
    @Test func fractionalFitTilesHaveNoWhiteSeams() throws {
        let size = CGSize(width: 3000, height: 3000)
        let context = try Renderer.bitmap(size: size)
        context.setFillColor(CGColor(gray: 0.5, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        let decoded: CGImage = try #require(context.makeImage())
        let source = SourceDocument(url: URL(fileURLWithPath: "/synthetic.png"), data: Data(), kind: .image,
            pageCount: 1, pixelWidth: 3000, pixelHeight: 3000, decodedImage: decoded, transparentImage: nil)
        var mark = WatermarkSettings(); mark.text = ""
        var output = ExportSettings(); output.format = .png
        let image = try decode(PreviewRendering.render(source, pageIndex: 0, watermark: mark, export: output,
            viewport: PreviewViewport(region: CGRect(origin: .zero, size: size), scale: 0.113, detailed: true)))
        let bytes = try pixels(image)
        let stride = bytes.count / image.height
        let values = (0..<image.height).flatMap { y in (0..<image.width).map { x in bytes[y * stride + x * 4] } }
        let minimum = try #require(values.min()), maximum = try #require(values.max())
        #expect(maximum - minimum <= 1, "Pixel range: \(minimum)...\(maximum)")
    }

}
