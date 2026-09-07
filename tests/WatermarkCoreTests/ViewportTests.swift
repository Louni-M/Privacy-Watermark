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
}
