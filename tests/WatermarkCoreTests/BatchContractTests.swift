import Foundation
import Testing
@testable import WatermarkCore

struct BatchContractTests {
    @Test func sharedPolicyAndDefaults() {
        let defaults = ExportSettings()
        #expect(defaults.flattened && defaults.dpi == 450)
        for (name, format) in [("a.JPG", OutputFormat.jpg), ("a.JPEG", .jpg), ("a.PNG", .png), ("a.PDF", .pdf)] {
            let url = URL(fileURLWithPath: "/synthetic/\(name)")
            let resolved = OutputPolicy.original.resolve(for: url, settings: defaults)
            #expect(resolved.format == format)
            #expect(resolved.flattened && resolved.dpi == 450)
            for policy in [OutputPolicy.jpg, .png, .pdf] {
                #expect(policy.resolve(for: url, settings: defaults).format.rawValue == policy.rawValue)
            }
        }
        var standard = defaults; standard.flattened = false; standard.dpi = 600
        #expect(OutputPolicy.png.resolve(for: URL(fileURLWithPath: "/a.pdf"), settings: standard).dpi == 600)
        #expect(!OutputPolicy.pdf.resolve(for: URL(fileURLWithPath: "/a.png"), settings: standard).flattened)
    }

    @Test func orderedSelectionAndIndependentStates() {
        var batch = BatchCollection()
        let urls = ["/synthetic/a.pdf", "/synthetic/b.png", "/elsewhere/a.pdf"].map { URL(fileURLWithPath: $0) }
        #expect(batch.append([urls[0]]) == 0)
        let first = batch.selectedID!
        #expect(batch.selected?.url == urls[0])
        #expect(batch.checkingCount == 1 && batch.readyCount == 0)
        #expect(batch.append(urls) == 1)
        #expect(batch.items.map(\.url) == urls)
        #expect(batch.selectedID == first)
        batch.update(first) { $0.validation = .invalid("Unreadable"); $0.export = .unprocessed }
        #expect(batch.selected?.validation == .invalid("Unreadable"))
        #expect(batch.selected?.export == .unprocessed)
        batch.remove(first)
        #expect(batch.selected?.url == urls[1])
        batch.select(batch.items.last!.id)
        batch.remove(batch.selectedID!)
        #expect(batch.selected?.url == urls[1])
        batch.clear()
        #expect(batch.items.isEmpty && batch.selectedID == nil)
    }
}
