import Foundation
import Testing
import CoreGraphics
import CoreText
@testable import WatermarkCore

struct WorkflowClarityTests {
    @Test func acceptedText() {
        #expect(WatermarkText.accepted("A\r\nB\rC\n\nD") == "A\nB\nC\n\nD")
        #expect(WatermarkText.accepted("") == "")
        let emoji = String(repeating: "👩🏽‍💻", count: 199)
        #expect(WatermarkText.accepted(emoji + "\nEXCESS") == emoji + "\n")
        #expect(WatermarkText.accepted(String(repeating: "é", count: 200)).count == 200)
    }

    @Test func todayDateInsertion() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-09T00:30:00Z"))
        let line = WatermarkText.dateLine(for: date, timeZone: TimeZone(secondsFromGMT: 0)!)
        #expect(line == "09-09-2026")
        #expect(WatermarkText.dateLine(for: date.addingTimeInterval(2 * 86400), timeZone: TimeZone(secondsFromGMT: 0)!) == "11-09-2026")
        #expect(WatermarkText.dateLine(for: date, timeZone: TimeZone(secondsFromGMT: -3600)!) == "08-09-2026")
        let original = "For: Example\nPurpose: Test"
        let added = WatermarkText.settingDateLine(line, included: true, in: original)
        #expect(added == original + "\n" + line)
        #expect(WatermarkText.containsDateLine(line, in: added))
        #expect(WatermarkText.settingDateLine(line, included: true, in: added) == added)
        #expect(WatermarkText.settingDateLine(line, included: false, in: added) == original)
        #expect(WatermarkText.settingDateLine(line, included: false, in: original) == original)
        #expect(WatermarkText.settingDateLine(line, included: true, in: "") == line)
        #expect(WatermarkText.settingDateLine(line, included: false, in: line) == "")
        let edited = added.replacingOccurrences(of: "09-09-2026", with: "10-09-2026")
        #expect(!WatermarkText.containsDateLine(line, in: edited))
        #expect(WatermarkText.settingDateLine(line, included: false, in: edited) == edited)
        let long = WatermarkText.settingDateLine(line, included: true, in: String(repeating: "👩🏽‍💻", count: 200))
        #expect(long.count == 200 && long.hasSuffix("\n" + line))
        #expect(WatermarkText.settingDateLine(line, included: false, in: long).count == 189)
        #expect(WatermarkText.settingDateLine(line, included: false, in: "Before\n" + line + "\nAfter") == "Before\nAfter")
    }

    func ready(_ name: String) throws -> BatchItem {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        var item = BatchItem(url: url)
        item.validation = .ready(ValidatedSource(try SourceDocument.load(url)))
        return item
    }

    @Test func predictedOutputsMatchPolicyAndValidation() throws {
        let pdf = try ready("document.pdf"), png = try ready("opaque.png"), jpg = try ready("photo.jpg")
        let settings = ExportSettings()
        for policy in OutputPolicy.allCases {
            let result = ExportPrediction(items: [pdf, png, jpg], policy: policy, settings: settings)
            #expect(result.documents == 3 && result.checking == 0 && result.excluded == 0)
            switch policy {
            case .original:
                #expect(result.pdfs == 1 && result.pngs == 1 && result.jpgs == 1 && result.pageFolders == 0)
            case .pdf:
                #expect(result.pdfs == 3 && result.pngs == 0 && result.jpgs == 0 && result.pageFolders == 0)
            case .jpg, .png:
                let pages = try #require(pdf.validation.metadata).pageCount
                #expect(result.jpgs + result.pngs == pages + 2)
                #expect(result.pageFolders == 1 && result.pageImages == pages && result.standaloneImages == 2)
            }
        }
        var invalid = BatchItem(url: URL(fileURLWithPath: "/fictional-invalid.pdf"))
        invalid.validation = .invalid("Invalid")
        let pending = BatchItem(url: URL(fileURLWithPath: "/fictional-pending.png"))
        let partial = ExportPrediction(items: [png, invalid, pending], policy: .original, settings: settings)
        #expect(partial.documents == 1 && partial.excluded == 1 && partial.checking == 1)
        #expect(partial.actionLabel == "Export 1 document…")
        #expect(partial.message.contains("incomplete") && partial.message.contains("excluded"))
        let empty = ExportPrediction(items: [], policy: .original, settings: settings)
        #expect(empty.documents == 0 && empty.actionLabel == "Export documents…")
        #expect(empty.message.contains("Add documents"))
    }

    @Test func singleLineRetainsLegacyGridAndPixels() throws {
        let size = CGSize(width: 595, height: 842)
        for direction in WatermarkDirection.allCases {
            var settings = WatermarkSettings(); settings.direction = direction
            let legacy = try Renderer.bitmap(size: size)
            let factor = min(size.width, size.height) / (210 / 25.4 * 72)
            legacy.scaleBy(x: factor, y: factor)
            let font = CTFontCreateWithName("Helvetica" as CFString, settings.size, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 0.09)
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: "COPY", attributes: attributes))
            let extent = max(CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)), settings.size) + 20
            var row = 0
            var y = -extent
            while y < size.height / factor + extent {
                var x = -extent + (row % 2 == 0 ? settings.spacing / 2 : 0)
                while x < size.width / factor + extent {
                    legacy.saveGState(); legacy.translateBy(x: x, y: y); legacy.rotate(by: direction.angle)
                    legacy.textMatrix = .identity; legacy.textPosition = .zero
                    CTLineDraw(line, legacy); legacy.restoreGState()
                    x += settings.spacing
                }
                y += settings.spacing; row += 1
            }
            let current = try Renderer.bitmap(size: size)
            Renderer.watermark(current, size: size, settings: settings, raster: true)
            #expect(Data(bytes: legacy.data!, count: legacy.bytesPerRow * legacy.height) == Data(bytes: current.data!, count: current.bytesPerRow * current.height))
        }
    }

    @Test func sampleIsLocalAndUsesWatermark() throws {
        var mark = WatermarkSettings()
        let first = try SampleDocument.render(watermark: mark)
        mark.text = "FIRST\nSECOND"
        #expect(try SampleDocument.render(watermark: mark) != first)
        mark.text = ""
        let empty = try SampleDocument.render(watermark: mark)
        mark.text = "COPY"; mark.opacity = 0
        #expect(try SampleDocument.render(watermark: mark) == empty)
        mark.opacity = 30; mark.size = 72; mark.spacing = 50
        mark.text = String(repeating: "\n", count: 199) + "X"
        let start = ContinuousClock.now
        #expect(try !SampleDocument.render(watermark: mark).isEmpty)
        #expect(start.duration(to: .now) < .seconds(2))
    }
}
