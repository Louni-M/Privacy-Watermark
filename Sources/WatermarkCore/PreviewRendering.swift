import Foundation
import CoreGraphics
import ImageIO
import PDFKit

public struct PreviewViewport: Equatable, Sendable {
    /// Document coordinates, with the same bottom-left origin as export rendering.
    public var region: CGRect
    public var scale: CGFloat
    public var backingScale: CGFloat
    public var detailed: Bool
    public init(region: CGRect, scale: CGFloat, backingScale: CGFloat = 1, detailed: Bool = false) {
        self.region = region
        self.scale = scale
        self.backingScale = backingScale
        self.detailed = detailed
    }
}

public enum PreviewRendering {
    public static let maximumPixels = 16_000_000

    public static func pageSizes(_ source: SourceDocument) throws -> [CGSize] {
        if source.kind == .image { return [CGSize(width: source.pixelWidth, height: source.pixelHeight)] }
        guard let pdf = PDFDocument(data: source.data) else { throw DocumentError.invalidPDF }
        return try (0..<pdf.pageCount).map { index in
            try Task.checkCancellation()
            guard let page = pdf.page(at: index) else { throw DocumentError.invalidPage }
            return Renderer.pageSize(page)
        }
    }

    public static func pageSize(_ source: SourceDocument, pageIndex: Int) throws -> CGSize {
        guard (0..<source.pageCount).contains(pageIndex) else { throw DocumentError.invalidPage }
        if source.kind == .image { return CGSize(width: source.pixelWidth, height: source.pixelHeight) }
        guard let page = PDFDocument(data: source.data)?.page(at: pageIndex) else { throw DocumentError.invalidPDF }
        return Renderer.pageSize(page)
    }

    public static func render(_ source: SourceDocument, pageIndex: Int, watermark: WatermarkSettings,
                              export: ExportSettings, viewport: PreviewViewport) throws -> Data {
        try watermark.validate()
        try export.validate()
        try Task.checkCancellation()
        let size = try pageSize(source, pageIndex: pageIndex)
        let region = viewport.region.intersection(CGRect(origin: .zero, size: size))
        let desiredScale = viewport.scale * viewport.backingScale
        guard desiredScale.isFinite, desiredScale > 0, !region.isNull,
              region.width > 0, region.height > 0 else { throw DocumentError.renderFailed }
        // A page image has only 72-DPI output detail. Images likewise never
        // promise pixels beyond the source's actual output dimensions.
        let outputScale = source.kind == .image || export.format != .pdf ? min(1, desiredScale)
            : export.flattened ? min(CGFloat(export.dpi) / 72, desiredScale) : desiredScale
        let width = ceil(region.width * outputScale), height = ceil(region.height * outputScale)
        guard width * height <= CGFloat(maximumPixels) else { throw DocumentError.renderFailed }
        let canvas = try Renderer.bitmap(size: region.size, scale: outputScale)
        let pdf = source.kind == .pdf ? PDFDocument(data: source.data) : nil
        let page = pdf?.page(at: pageIndex)
        let rasterScale: CGFloat
        if source.kind == .image { rasterScale = viewport.detailed ? 1 : outputScale }
        else if export.flattened && viewport.detailed { rasterScale = CGFloat(export.dpi) / 72 }
        else { rasterScale = outputScale }

        // Work in bounded strips/columns inside this single viewport. This is
        // transient raster scratch space, not a cache of full pages or tiles.
        // Padding gives JPEG and downsampling their neighboring edge pixels.
        let chunkSide = floor(sqrt(CGFloat(maximumPixels) / 2)) - 32
        let step = max(1, floor(chunkSide / rasterScale))
        var y: CGFloat = 0
        while y < region.height {
            var x: CGFloat = 0
            while x < region.width {
                try Task.checkCancellation()
                try autoreleasepool {
                    let target = CGRect(x: region.minX + x, y: region.minY + y,
                        width: min(step, region.width - x), height: min(step, region.height - y))
                    let padding = 16 / rasterScale
                    let expanded = target.insetBy(dx: -padding, dy: -padding)
                        .intersection(CGRect(origin: .zero, size: size))
                    let image: CGImage
                    if let page {
                        image = try Renderer.renderPage(page, settings: watermark, scale: rasterScale,
                            raster: export.flattened, region: expanded)
                    } else {
                        image = try Renderer.renderImage(source, settings: watermark, region: expanded, renderScale: rasterScale)
                    }
                    var rendered = image
                    if viewport.detailed && (source.kind == .pdf && export.flattened || source.kind == .image && export.format == .pdf) {
                        let quality = source.kind == .pdf && export.flattened ? 0.95 : 0.9
                        rendered = try Renderer.jpegImage(image, quality: quality,
                            maximumDimension: max(expanded.width, expanded.height) * outputScale)
                    }
                    canvas.saveGState()
                    // Tile boundaries are coverage boundaries, not drawn edges.
                    // Antialiasing fractional clips leaves white seams at fit scales.
                    canvas.setShouldAntialias(false)
                    canvas.clip(to: target.offsetBy(dx: -region.minX, dy: -region.minY))
                    canvas.draw(rendered, in: expanded.offsetBy(dx: -region.minX, dy: -region.minY))
                    canvas.restoreGState()
                }
                x += step
            }
            y += step
        }
        try Task.checkCancellation()
        guard var result = canvas.makeImage() else { throw DocumentError.renderFailed }
        if viewport.detailed && export.format == .jpg {
            result = try Renderer.jpegImage(result, quality: 0.9, maximumDimension: max(CGFloat(result.width), CGFloat(result.height)))
        }
        return try Renderer.encoded(result, format: .png)
    }
}
