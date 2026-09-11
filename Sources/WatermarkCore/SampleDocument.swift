import Foundation
import CoreGraphics
import CoreText

public enum SampleDocument {
    /// Fictional in-memory content; it never has a source identity or export destination.
    public static func render(watermark: WatermarkSettings) throws -> Data {
        try watermark.validate()
        let size = CGSize(width: 595, height: 760)
        let context = try Renderer.bitmap(size: size)
        func text(_ string: String, x: CGFloat, y: CGFloat, size: CGFloat, gray: CGFloat) {
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, size, nil),
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: gray, alpha: 1)
            ]
            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes)), context)
        }
        text("EXAMPLE DOCUMENT", x: 48, y: 680, size: 24, gray: 0.15)
        text("Fictional content · Try your watermark", x: 48, y: 644, size: 15, gray: 0.4)
        context.setFillColor(CGColor(gray: 0.93, alpha: 1))
        context.fill(CGRect(x: 48, y: 450, width: 110, height: 145))
        text("SAMPLE", x: 64, y: 516, size: 16, gray: 0.45)
        for (index, title) in ["Reference: EXAMPLE-001", "Prepared for demonstration", "No personal information"].enumerated() {
            text(title, x: 188, y: 567 - CGFloat(index) * 40, size: 16, gray: 0.3)
        }
        for index in 0..<8 {
            context.setFillColor(CGColor(gray: 0.87, alpha: 1))
            context.fill(CGRect(x: 48, y: 376 - CGFloat(index) * 30, width: index % 3 == 2 ? 350 : 499, height: 5))
        }
        text("Adjust the text and appearance to see the result.", x: 48, y: 76, size: 14, gray: 0.4)
        Renderer.watermark(context, size: size, settings: watermark, raster: true)
        guard let image = context.makeImage() else { throw DocumentError.renderFailed }
        return try Renderer.encoded(image, format: .png)
    }
}
