import Foundation
import Testing
@testable import PWMCommand
import WatermarkCore

struct ArgumentTests {
    // 12 October 2026, noon UTC.
    let today = Date(timeIntervalSince1970: 1_791_806_400)
    let utc = TimeZone(identifier: "UTC")!

    func request(_ arguments: [String], preset: Preset? = nil) throws -> ExportRequest {
        try RequestResolver.resolve(ArgumentParser.parse(arguments), preset: preset, today: today, timeZone: utc)
    }

    func error(_ arguments: [String], preset: Preset? = nil) -> CommandError? {
        do { _ = try request(arguments, preset: preset); return nil } catch let error as CommandError { return error } catch { return nil }
    }

    @Test func defaultsMatchTheApp() throws {
        let result = try request(["COPY", "contract.pdf"])
        #expect(result.files == ["contract.pdf"])
        #expect(result.watermark.text == "COPY")
        let app = WatermarkSettings()
        #expect(result.watermark.opacity == app.opacity && result.watermark.size == app.size && result.watermark.spacing == app.spacing)
        #expect(result.watermark.color == app.color && result.watermark.direction == app.direction)
        #expect(result.settings == ExportSettings())
        #expect(result.policy == .original && result.out == nil && !result.stripOnly && result.suffix == "_watermarked")
    }

    @Test func everyOptionMapsToItsSetting() throws {
        let result = try request(["--opacity", "45.5", "--size=20", "--spacing", "300", "--color", "Gray", "--direction", "down",
                                  "--format", "png", "--pdf-mode", "text", "--dpi", "600", "-o", "out", "Hi", "a.jpg", "b.pdf"])
        #expect(result.watermark.opacity == 45.5 && result.watermark.size == 20 && result.watermark.spacing == 300)
        #expect(result.watermark.color == .gray && result.watermark.direction == .descending)
        #expect(result.policy == .png && !result.settings.flattened && result.settings.dpi == 600)
        #expect(result.out == "out" && result.files == ["a.jpg", "b.pdf"] && result.watermark.text == "Hi")
        for (value, policy) in [("keep", OutputPolicy.original), ("pdf", .pdf), ("jpg", .jpg), ("jpeg", .jpg)] {
            #expect(try request(["T", "a.png", "--format", value]).policy == policy)
        }
        #expect(try request(["T", "a.png", "--color", "white"]).watermark.color == .white)
        #expect(try request(["T", "a.png", "--direction", "up"]).watermark.direction == .ascending)
        #expect(try request(["T", "a.png", "--pdf-mode", "flattened", "--dpi", "300"]).settings.dpi == 300)
    }

    @Test func optionsMayBeInterleavedAndDashPathsFollowSeparator() throws {
        let result = try request(["COPY", "--date", "a.jpg", "--opacity", "10", "--", "-scan.pdf", "--help"])
        #expect(result.files == ["a.jpg", "-scan.pdf", "--help"])
        #expect(result.watermark.opacity == 10)
        #expect(try request(["COPY", "-"]).files == ["-"])
    }

    @Test func invalidValuesAreUsageErrors() {
        let cases: [([String], String)] = [
            (["--opacity", "150"], "--opacity"), (["--opacity", "-1"], "--opacity"), (["--opacity", "nan"], "--opacity"),
            (["--size", "11"], "--size"), (["--size", "73"], "--size"), (["--spacing", "49"], "--spacing"),
            (["--spacing", "301"], "--spacing"), (["--color", "red"], "--color"), (["--direction", "left"], "--direction"),
            (["--format", "gif"], "--format"), (["--pdf-mode", "vector"], "--pdf-mode"), (["--dpi", "200"], "--dpi"),
            (["--date=yes"], "--date")
        ]
        for (options, option) in cases {
            guard case .invalidValue(let name, _, _) = error(["T", "a.jpg"] + options) else {
                Issue.record("Expected invalid value for \(options)"); continue
            }
            #expect(name == option)
            #expect(CommandError.invalidValue(option: name, value: "", expected: "").status == .usage)
        }
    }

    @Test func malformedCommandLines() {
        #expect(error(["T", "a.jpg", "--colour", "red"]) == .unknownOption("--colour"))
        #expect(error(["T", "a.jpg", "-x"]) == .unknownOption("-x"))
        #expect(error(["T", "a.jpg", "--opacity"]) == .missingValue("--opacity"))
        #expect(error([]) == .missingText)
        #expect(error(["--date"]) == .missingText)
        #expect(error(["COPY"]) == .missingFiles)
        #expect(error(["--text", "COPY"]) == .missingFiles)
        #expect(CommandError.missingFiles.report.hasSuffix("Run pwm --help for usage."))
    }

    @Test func textLineBreaksDateAndLimit() throws {
        #expect(try request(["Line one\\nLine two", "a.jpg"]).watermark.text == "Line one\nLine two")
        #expect(try request(["A\r\nB\rC", "a.jpg"]).watermark.text == "A\nB\nC")
        #expect(try request(["Dossier location — Hôtel-de-Ville", "a.jpg", "--date"]).watermark.text
            == "Dossier location — Hôtel-de-Ville\n12-10-2026")
        #expect(try request(["", "a.jpg", "--date"]).watermark.text == "12-10-2026")
        #expect(try request(["", "a.jpg"]).watermark.text == "")
        #expect(try request(["Signed\n12-10-2026", "a.jpg", "--date"]).watermark.text == "Signed\n12-10-2026")
        let exact = String(repeating: "é", count: 200)
        #expect(try request([exact, "a.jpg"]).watermark.text == exact)
        #expect(error([exact + "x", "a.jpg"]) == .textTooLong(201))
        let nearly = String(repeating: "a", count: 190)
        #expect(error([nearly, "a.jpg", "--date"]) == .textTooLong(201))
        #expect(CommandError.textTooLong(201).message.contains("201"))
    }

    @Test func textOptionMakesEveryPositionalAFile() throws {
        let result = try request(["--text", "COPY", "a.jpg", "b.png"])
        #expect(result.watermark.text == "COPY" && result.files == ["a.jpg", "b.png"])
    }

    @Test func stripOnlyTakesOnlyFilesAndOutput() throws {
        let result = try request(["--strip-only", "IMG_0042.jpg", "b.png", "--out", "clean"])
        #expect(result.stripOnly && result.suffix == "_stripped" && result.files == ["IMG_0042.jpg", "b.png"])
        #expect(result.watermark.text == "" && result.policy == .original && result.out == "clean")
        #expect(error(["--strip-only"]) == .missingFiles)
        for option in [["--opacity", "10"], ["--date"], ["--text", "x"], ["--format", "png"], ["--preset", "p"], ["--dpi", "300"]] {
            #expect(error(["--strip-only", "a.jpg"] + option) == .notWithStripOnly(option[0]))
        }
    }
}
