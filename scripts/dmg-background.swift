import AppKit

// Installation artwork is generated at 2x resolution; coordinates are shared
// with dmg-settings.py. No source-app resources are modified.
let width = 660
let height = 440
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * 2,
    pixelsHigh: height * 2, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!
bitmap.size = NSSize(width: width, height: height)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func label(_ text: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    (text as NSString).draw(in: NSRect(x: 24, y: y, width: 612, height: 40), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color, .paragraphStyle: style
    ])
}
label("Passport Filigrane", y: 352, size: 28, weight: .semibold, color: .darkGray)
label("Drag the app into Applications", y: 316, size: 16, weight: .regular, color: .darkGray)
label("→", y: 208, size: 36, weight: .medium, color: .systemGray)
label("First launch blocked? Open Install.txt below.", y: 112, size: 13, weight: .regular, color: .darkGray)
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
