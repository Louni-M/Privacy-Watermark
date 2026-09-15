import Foundation
import CoreGraphics
import CoreText
import Testing
@testable import WatermarkCore

struct AdaptiveWatermarkTests {
    func layout(_ settings: WatermarkSettings) -> WatermarkLayout {
        WatermarkLayout(settings: settings, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, settings.size, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1)
        ])
    }

    @Test func blocksAndLinesStaySeparated() {
        let texts = ["For rental application\nÉlodie — Zürich\n15-09-2026", String(repeating: "Long text ", count: 20),
                     "Égj\ne\u{301} Å\n姓名 👨‍👩‍👧‍👦", "COPY\n\nDATE", String(repeating: "\n", count: 198) + "X"]
        for text in texts {
            for direction in WatermarkDirection.allCases {
                for size in [36.0, 72.0] {
                    var settings = WatermarkSettings()
                    settings.text = text; settings.size = size; settings.spacing = 50; settings.direction = direction
                    let geometry = layout(settings)
                    #expect(!geometry.usesLegacyGrid)
                    #expect(geometry.pitch.width > geometry.blockBounds.width)
                    #expect(geometry.pitch.height > geometry.blockBounds.height)
                    let center = geometry.blockBounds
                    for row in -2...2 {
                        for column in -2...2 where row != 0 || column != 0 {
                            let neighbor = center.offsetBy(dx: CGFloat(column) * geometry.pitch.width + (row % 2 == 0 ? 0 : geometry.pitch.width / 2),
                                                           dy: CGFloat(row) * geometry.pitch.height)
                            #expect(!center.intersects(neighbor))
                        }
                    }
                    // Unrotate each measured line and compare neighboring baselines.
                    for index in 1..<geometry.lines.count {
                        let previous = CTLineGetBoundsWithOptions(geometry.lines[index - 1], .useGlyphPathBounds)
                        let current = CTLineGetBoundsWithOptions(geometry.lines[index], .useGlyphPathBounds)
                        if previous.height > 0 && current.height > 0 {
                            #expect(current.maxY - geometry.lineDistance < previous.minY)
                        }
                    }
                    settings.spacing = 300
                    let wider = layout(settings)
                    #expect(wider.pitch.width >= geometry.pitch.width && wider.pitch.height >= geometry.pitch.height)
                }
            }
        }
    }

    @Test func centralAnchorAndLegacyCompatibility() {
        var settings = WatermarkSettings()
        #expect(layout(settings).usesLegacyGrid)
        settings.text = "Purpose\nName\nDate"
        let geometry = layout(settings)
        let size = CGSize(width: 595, height: 842)
        let anchor = geometry.anchor(in: size)
        #expect(CGRect(origin: .zero, size: size).contains(geometry.blockBounds.offsetBy(dx: anchor.x, dy: anchor.y)))
    }

    @Test func oversizedAndWhitespaceRenderingIsBoundedAndVisible() throws {
        for text in [String(repeating: "\n", count: 198) + "X", String(repeating: "W", count: 200), String(repeating: " ", count: 199) + "X", "X" + String(repeating: " ", count: 199), "X" + String(repeating: " ", count: 198) + "X", "É\n姓名\n😀", " \n \t "] {
            for direction in WatermarkDirection.allCases {
                var settings = WatermarkSettings()
                settings.text = text; settings.size = 72; settings.spacing = 50; settings.opacity = 100; settings.direction = direction
                let started = ContinuousClock.now
                let context = try Renderer.bitmap(size: CGSize(width: 595, height: 842))
                Renderer.watermark(context, size: CGSize(width: 595, height: 842), settings: settings, raster: true)
                #expect(started.duration(to: .now) < .seconds(3))
                let bytes = context.data!.assumingMemoryBound(to: UInt8.self)
                var marked = false
                for y in 0..<context.height {
                    for x in 0..<context.width where bytes[y * context.bytesPerRow + x * 4] < 240 { marked = true }
                }
                #expect(marked == !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
