import Foundation
import CoreGraphics
import CoreText

/// Geometry in normalized full-page coordinates, shared by preview and export.
struct WatermarkLayout {
    let lines: [CTLine]
    let drawableIndices: [Int]
    let lineDistance: CGFloat
    let width: CGFloat
    let rotatedLineBounds: [CGRect]
    let rotatedInkBounds: [CGRect]
    let blockBounds: CGRect
    let pitch: CGSize
    let usesLegacyGrid: Bool
    private let rotation: CGAffineTransform

    init(settings: WatermarkSettings, attributes: [NSAttributedString.Key: Any]) {
        let strings = WatermarkText.accepted(settings.text).components(separatedBy: "\n")
        lines = strings.map { CTLineCreateWithAttributedString(NSAttributedString(string: $0, attributes: attributes)) }
        drawableIndices = strings.indices.filter { !strings[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var widest: CGFloat = 0
        let bounds = lines.map { line -> CGRect in
            var ascent: CGFloat = 0, descent: CGFloat = 0
            let advance = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
            widest = max(widest, advance)
            // Typographic bounds cover color/fallback glyphs as well as spaces;
            // path bounds also cover accents and overhanging glyph outlines.
            let typographic = CGRect(x: 0, y: -descent, width: advance, height: ascent + descent)
            return typographic.union(CTLineGetBoundsWithOptions(line, .useGlyphPathBounds))
        }
        width = widest
        let top = bounds.map(\.maxY).max() ?? 0
        let bottom = bounds.map(\.minY).min() ?? 0
        let clearance = settings.size * 0.25
        lineDistance = max(settings.size * 1.2, top - bottom + clearance)
        let rotation = CGAffineTransform(rotationAngle: settings.direction.angle)
        self.rotation = rotation
        let distance = lineDistance
        rotatedLineBounds = bounds.enumerated().map { index, rect in
            rect.offsetBy(dx: 0, dy: -CGFloat(index) * distance).applying(rotation)
        }
        rotatedInkBounds = lines.enumerated().map { index, line in
            let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            let visible = ink.isNull || ink.isEmpty ? bounds[index] : ink
            return visible.offsetBy(dx: 0, dy: -CGFloat(index) * distance).applying(rotation)
        }
        // Retain blank-line height even when those lines have no ink.
        var unrotated = CGRect(x: 0, y: -CGFloat(lines.count - 1) * distance + bottom,
                               width: widest, height: CGFloat(lines.count - 1) * distance + top - bottom)
        for (index, rect) in bounds.enumerated() {
            unrotated = unrotated.union(rect.offsetBy(dx: 0, dy: -CGFloat(index) * distance))
        }
        blockBounds = unrotated.applying(rotation)
        pitch = CGSize(width: max(settings.spacing, blockBounds.width + clearance),
                       height: max(settings.spacing, blockBounds.height + clearance))
        usesLegacyGrid = lines.count == 1 && pitch.width == settings.spacing && pitch.height == settings.spacing
    }

    func anchor(in size: CGSize) -> CGPoint {
        let target: CGRect
        if blockBounds.width <= size.width && blockBounds.height <= size.height {
            target = blockBounds
        } else if let first = drawableIndices.first {
            // Center actual ink, not leading/trailing spaces that could place
            // the only visible glyph beyond the page in an oversized line.
            let ink = rotatedInkBounds[first]
            if ink.width <= size.width && ink.height <= size.height {
                target = ink
            } else {
                // A line such as X + many spaces + X can have an empty center.
                // Put an actual glyph on the page when even the ink span is too wide.
                let runs = CTLineGetGlyphRuns(lines[first]) as! [CTRun]
                let glyph = runs.lazy.compactMap { run -> CGRect? in
                    for index in 0..<CTRunGetGlyphCount(run) {
                        let rect = CTRunGetImageBounds(run, nil, CFRange(location: index, length: 1))
                        if !rect.isNull && !rect.isEmpty { return rect }
                    }
                    return nil
                }.first
                if let glyph {
                    target = glyph.offsetBy(dx: 0, dy: -CGFloat(first) * lineDistance).applying(rotation)
                } else {
                    target = ink
                }
            }
        } else {
            target = .zero
        }
        return CGPoint(x: size.width / 2 - target.midX, y: size.height / 2 - target.midY)
    }
}
