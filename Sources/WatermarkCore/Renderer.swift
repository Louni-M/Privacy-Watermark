import Foundation
import CoreGraphics
import CoreText
import ImageIO
import PDFKit
import UniformTypeIdentifiers

enum Renderer {
    static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    static func bitmap(size: CGSize, scale: CGFloat = 1) throws -> CGContext {
        let w = ceil(size.width * scale), h = ceil(size.height * scale)
        guard w.isFinite, h.isFinite, w > 0, h > 0, w <= CGFloat(Int32.max), h <= CGFloat(Int32.max),
              w * h * 4 <= CGFloat(Int.max) else { throw DocumentError.renderFailed }
        guard let context = CGContext(data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8,
                                      bytesPerRow: 0, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw DocumentError.renderFailed }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))
        context.scaleBy(x: scale, y: scale)
        context.interpolationQuality = .high
        return context
    }

    static func imageSource(_ source: SourceDocument) throws -> CGImage {
        guard let image = source.decodedImage else { throw DocumentError.invalidImage }
        return image
    }

    static func opaqueImage(_ image: CGImage) -> CGImage {
        // Pillow's RGBA -> RGB output discards alpha without compositing a white
        // background. ImageIO exposes straight-alpha PNG pixels; keep those RGB
        // values, including hidden pixels, for the same opaque output behavior.
        if image.alphaInfo == .last || image.alphaInfo == .first {
            let alpha = image.alphaInfo == .last ? CGImageAlphaInfo.noneSkipLast : .noneSkipFirst
            let bitmapInfo = CGBitmapInfo(rawValue: (image.bitmapInfo.rawValue & ~CGBitmapInfo.alphaInfoMask.rawValue) | alpha.rawValue)
            if let provider = image.dataProvider, let opaque = CGImage(width: image.width, height: image.height,
                bitsPerComponent: image.bitsPerComponent, bitsPerPixel: image.bitsPerPixel,
                bytesPerRow: image.bytesPerRow, space: image.colorSpace ?? colorSpace, bitmapInfo: bitmapInfo,
                provider: provider, decode: image.decode, shouldInterpolate: true, intent: image.renderingIntent) { return opaque }
        }
        return image
    }

    static func pageSize(_ page: PDFPage) -> CGSize {
        let box = page.bounds(for: .cropBox)
        return page.rotation % 180 == 0 ? box.size : CGSize(width: box.height, height: box.width)
    }

    /// Native vector text stays selectable in standard PDFs. Legacy raster stamps
    /// used their alpha twice (paste mask, then compositing); retain that appearance.
    static func watermark(_ context: CGContext, size: CGSize, settings: WatermarkSettings, raster: Bool) {
        guard !settings.text.isEmpty, settings.opacity > 0 else { return }
        let opacity = settings.opacity / 100
        let alpha = raster ? opacity * opacity : opacity
        let color = CGColor(gray: settings.color.component, alpha: alpha)
        let font = CTFontCreateWithName("Helvetica" as CFString, settings.size, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: settings.text, attributes: attributes))
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let extent = max(width, settings.size) + 20
        let step = settings.spacing
        var row = 0
        var y = -extent
        while y < size.height + extent {
            var x = -extent + (row % 2 == 0 ? step / 2 : 0)
            while x < size.width + extent {
                context.saveGState()
                context.translateBy(x: x, y: y)
                context.rotate(by: settings.direction.angle)
                context.textMatrix = .identity
                context.textPosition = .zero
                CTLineDraw(line, context)
                context.restoreGState()
                x += step
            }
            y += step
            row += 1
        }
    }

    static func renderImage(_ source: SourceDocument, settings: WatermarkSettings, maxDimension: CGFloat? = nil) throws -> CGImage {
        let image = try imageSource(source)
        let size = CGSize(width: image.width, height: image.height)
        let scale = maxDimension.map { min(1, $0 / max(size.width, size.height)) } ?? 1
        let context = try bitmap(size: size, scale: scale)
        context.draw(image, in: CGRect(origin: .zero, size: size))
        watermark(context, size: size, settings: settings, raster: true)
        guard let result = context.makeImage() else { throw DocumentError.renderFailed }
        return result
    }

    static func renderPage(_ page: PDFPage, settings: WatermarkSettings, scale: CGFloat, raster: Bool) throws -> CGImage {
        let size = pageSize(page)
        let context = try bitmap(size: size, scale: scale)
        context.saveGState()
        page.draw(with: .cropBox, to: context)
        context.restoreGState()
        watermark(context, size: size, settings: settings, raster: raster)
        guard let image = context.makeImage() else { throw DocumentError.renderFailed }
        return image
    }

    static func encoded(_ image: CGImage, format: OutputFormat, quality: Double = 0.9) throws -> Data {
        let data = NSMutableData()
        let type = format == .png ? UTType.png.identifier : UTType.jpeg.identifier
        guard let destination = CGImageDestinationCreateWithData(data, type as CFString, 1, nil) else { throw DocumentError.writeFailed }
        // Only encoding properties are passed, never source EXIF/GPS dictionaries.
        let properties: [CFString: Any] = format == .png
            ? [kCGImagePropertyPNGDictionary: [kCGImagePropertyPNGCompressionFilter: IMAGEIO_PNG_FILTER_SUB]]
            : [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImageAndMetadata(destination, image, CGImageMetadataCreateMutable(), properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw DocumentError.writeFailed }
        return try ImageMetadata.removingAncillaryMetadata(data as Data, format: format)
    }

    static func jpegImage(_ image: CGImage, quality: Double) throws -> CGImage {
        let data = try encoded(image, format: .jpg, quality: quality)
        guard let provider = CGDataProvider(data: data as CFData),
              let result = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { throw DocumentError.renderFailed }
        return result
    }
}
