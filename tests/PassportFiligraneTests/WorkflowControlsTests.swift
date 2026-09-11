import Foundation
import Testing
import WatermarkCore
@testable import PassportFiligrane

@MainActor struct WorkflowControlsTests {
    @Test func numericDrafts() {
        let locale = Locale(identifier: "en_US")
        for (draft, expected) in [("36.5", 36.5), ("100", 72.0), ("-4", 12.0), ("", 36.0), ("hello", 36.0), ("NaN", 36.0), ("42junk", 36.0)] {
            #expect(AppearanceNumber.commit(draft, previous: 36, range: 12...72, locale: locale) == expected, "\(draft)")
        }
        #expect(AppearanceNumber.commit("36,5", previous: 36, range: 12...72, locale: Locale(identifier: "fr_FR")) == 36.5)
    }

    @Test func resetAndEligibility() async throws {
        let session = Session()
        let helpers = SessionTests()
        session.add([helpers.fixture("photo.jpg"), helpers.fixture("document.pdf"), helpers.fixture("corrupt.pdf")])
        try await helpers.wait { !session.isLoading }
        session.watermark.text = "For: Example\nPurpose: Test"
        session.watermark.opacity = 0
        session.watermark.size = 60
        session.watermark.spacing = 250
        session.watermark.color = .white
        session.watermark.direction = .descending
        session.outputPolicy = .png
        #expect(session.canExport)
        #expect(session.exportPrediction.documents == 2 && session.exportPrediction.excluded == 1)
        let prediction = session.exportPrediction
        session.select(session.batch.items[1].id)
        #expect(session.exportPrediction == prediction)
        session.resetAppearance()
        var expected = WatermarkSettings(); expected.text = "For: Example\nPurpose: Test"
        #expect(session.watermark == expected && session.outputPolicy == .png && session.batch.items.count == 3)
        session.watermark.text = ""
        #expect(session.canExport)
        session.clearAll()
        #expect(!session.canExport && session.exportPrediction.documents == 0)
        #expect(session.watermark.text.isEmpty && session.outputPolicy == .png)
    }

    @Test func invalidFirstImportAndReturnToSampleState() async throws {
        let session = Session()
        let helpers = SessionTests()
        session.watermark.text = "For: Example\nPurpose: Test"
        session.add([helpers.fixture("corrupt.pdf")])
        #expect(session.isLoading && !session.canExport && session.exportPrediction.checking == 1)
        try await helpers.wait { !session.isLoading }
        #expect(session.batch.items.count == 1 && session.selected?.validation.metadata == nil)
        #expect(session.preview == nil && session.exportPrediction.excluded == 1 && !session.canExport)
        session.remove(try #require(session.selected).id)
        #expect(session.batch.items.isEmpty && session.selected == nil && !session.canExport)
        #expect(session.watermark.text == "For: Example\nPurpose: Test")
    }
}
