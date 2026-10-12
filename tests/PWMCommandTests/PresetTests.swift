import Foundation
import Testing
@testable import PWMCommand
import WatermarkCore

@Suite(.serialized)
struct PresetTests {
    // 12 October 2026, noon UTC.
    let today = Date(timeIntervalSince1970: 1_791_806_400)
    let utc = TimeZone(identifier: "UTC")!

    let rental = """
    { "presets": {
        "rental": { "text": "Rental application", "date": true, "opacity": 40 },
        "dark":   { "color": "white", "direction": "down", "size": 20, "spacing": 300,
                    "format": "png", "pdf-mode": "text", "dpi": 600 }
    } }
    """

    /// A temporary XDG_CONFIG_HOME holding the given preset file contents.
    func config(_ contents: String?, in workspace: Workspace) throws -> [String: String] {
        let home = try workspace.folder("config")
        if let contents {
            try workspace.folder("config/pwm")
            try Data(contents.utf8).write(to: home.appendingPathComponent("pwm/presets.json"))
        }
        return ["XDG_CONFIG_HOME": home.path, "HOME": workspace.url("home").path]
    }

    @Test func locationFollowsXDGThenHome() {
        #expect(PresetFile.location(environment: ["XDG_CONFIG_HOME": "/x/cfg", "HOME": "/u/me"]) == "/x/cfg/pwm/presets.json")
        #expect(PresetFile.location(environment: ["HOME": "/u/me"]) == "/u/me/.config/pwm/presets.json")
        // A relative XDG_CONFIG_HOME is ignored, as the XDG specification requires.
        #expect(PresetFile.location(environment: ["XDG_CONFIG_HOME": "cfg", "HOME": "/u/me"]) == "/u/me/.config/pwm/presets.json")
    }

    @Test func presetValuesApplyAndExplicitOptionsOverride() throws {
        let file = try PresetFile(path: "presets.json", data: Data(rental.utf8))
        #expect(file.names == ["dark", "rental"])
        func request(_ arguments: [String], preset: String) throws -> ExportRequest {
            try RequestResolver.resolve(ArgumentParser.parse(arguments), preset: file.presets[preset], today: today, timeZone: utc)
        }

        let used = try request(["--preset", "rental", "id.jpg", "payslip.pdf"], preset: "rental")
        #expect(used.files == ["id.jpg", "payslip.pdf"])
        #expect(used.watermark.text == "Rental application\n12-10-2026" && used.watermark.opacity == 40)
        #expect(used.watermark.size == WatermarkSettings().size)

        let overridden = try request(["--preset", "rental", "id.jpg", "--opacity", "20", "--text", "Guarantor file"], preset: "rental")
        #expect(overridden.watermark.text == "Guarantor file\n12-10-2026" && overridden.watermark.opacity == 20)
        #expect(overridden.files == ["id.jpg"])
        #expect(try request(["--preset", "rental", "id.jpg", "--no-date"], preset: "rental").watermark.text == "Rental application")

        let dark = try request(["COPY", "a.pdf", "--preset", "dark", "--dpi", "300"], preset: "dark")
        #expect(dark.watermark.text == "COPY" && dark.files == ["a.pdf"])
        #expect(dark.watermark.color == .white && dark.watermark.direction == .descending)
        #expect(dark.watermark.size == 20 && dark.watermark.spacing == 300)
        #expect(dark.policy == .png && !dark.settings.flattened && dark.settings.dpi == 300)
        // Without preset text, the first positional is still TEXT.
        #expect(throws: CommandError.missingText) { try request(["--preset", "dark"], preset: "dark") }
        #expect(throws: CommandError.missingFiles) { try request(["--preset", "dark", "a.pdf"], preset: "dark") }
    }

    @Test func invalidPresetFilesAreConfigurationErrors() throws {
        let cases: [(String, String)] = [
            ("{ \"presets\": ", "not valid JSON"),
            ("[]", "\"presets\" object"),
            ("{ \"presets\": { \"a\": 3 } }", "preset \"a\" must be an object"),
            ("{ \"presets\": { \"a\": { \"opacity\": 150 } } }", "opacity must be a number from 0 to 100"),
            ("{ \"presets\": { \"a\": { \"opacity\": true } } }", "opacity must be a number"),
            ("{ \"presets\": { \"a\": { \"size\": 11 } } }", "size must be a number from 12 to 72"),
            ("{ \"presets\": { \"a\": { \"spacing\": 301 } } }", "spacing must be a number from 50 to 300"),
            ("{ \"presets\": { \"a\": { \"color\": \"red\" } } }", "color must be white, black or gray"),
            ("{ \"presets\": { \"a\": { \"direction\": \"left\" } } }", "direction must be up or down"),
            ("{ \"presets\": { \"a\": { \"format\": \"gif\" } } }", "format must be keep, pdf, jpg or png"),
            ("{ \"presets\": { \"a\": { \"pdf-mode\": \"vector\" } } }", "pdf-mode must be flattened or text"),
            ("{ \"presets\": { \"a\": { \"dpi\": 200 } } }", "dpi must be 300, 450 or 600"),
            ("{ \"presets\": { \"a\": { \"date\": \"yes\" } } }", "date must be true or false"),
            ("{ \"presets\": { \"a\": { \"text\": 3 } } }", "text must be a string"),
            ("{ \"presets\": { \"a\": { \"opactiy\": 3 } } }", "unknown setting \"opactiy\""),
            ("{ \"presets\": { \"a\": { \"text\": \"\(String(repeating: "x", count: 201))\" } } }", "longer than 200")
        ]
        for (contents, problem) in cases {
            do {
                _ = try PresetFile(path: "/cfg/pwm/presets.json", data: Data(contents.utf8))
                Issue.record("Expected a preset file error for \(contents)")
            } catch {
                #expect(error.status == .configuration)
                #expect(error.message.contains("/cfg/pwm/presets.json") && error.message.contains(problem), "\(error.message)")
            }
        }
    }

    @Test func commandReadsPresetsOnlyWhenRequested() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let image = try workspace.image("in/id.jpg")

        // Missing file: no error unless a preset is requested.
        let missing = try config(nil, in: workspace)
        #expect(await runCommand(["--list-presets"], environment: missing).status == .success)
        let noFile = await runCommand(["--preset", "rental", image.path], environment: missing)
        #expect(noFile.status == .configuration && noFile.errorText.contains("presets.json"))
        #expect(await runCommand(["COPY", image.path], environment: missing).status == .success)

        // Malformed file: only a run that requests a preset fails, with 78 and the file named.
        let broken = try config("{ not json", in: workspace)
        let malformed = await runCommand(["--preset", "rental", image.path], environment: broken)
        #expect(malformed.status == .configuration && malformed.output.isEmpty)
        #expect(malformed.errorText.contains(workspace.url("config/pwm/presets.json").path))
        #expect(await runCommand(["--list-presets"], environment: broken).status == .configuration)
        #expect(await runCommand(["COPY", image.path, "--opacity", "10"], environment: broken).status == .success)

        let outOfRange = try config("{ \"presets\": { \"rental\": { \"dpi\": 72 } } }", in: workspace)
        let range = await runCommand(["--preset", "rental", image.path], environment: outOfRange)
        #expect(range.status == .configuration && range.errorText.contains("dpi"))
        #expect(!FileManager.default.fileExists(atPath: workspace.url("in/id_watermarked (3).jpg").path))
    }

    @Test func presetRunsListsAndUnknownNames() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let environment = try config(rental, in: workspace)
        let file = workspace.url("config/pwm/presets.json")
        let before = try sha256(file)
        let modified = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        let id = try workspace.image("in/id.jpg"), payslip = try workspace.pdf("in/payslip.pdf")

        let listed = await runCommand(["--list-presets"], environment: environment)
        #expect(listed.status == .success && listed.output == ["dark", "rental"] && listed.errors.isEmpty)

        let unknown = await runCommand(["--preset", "lease", id.path], environment: environment)
        #expect(unknown.status == .usage && unknown.errorText.contains("\"lease\"") && unknown.errorText.contains("--help"))

        let used = await runCommand(["--preset", "rental", id.path, payslip.path], environment: environment)
        #expect(used.status == .success, "\(used.errors)")
        #expect(used.output == [workspace.url("in/id_watermarked.jpg").path, workspace.url("in/payslip_watermarked.pdf").path])
        #expect(!used.errorText.contains("Rental application"))

        #expect(try sha256(file) == before)
        #expect(try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date == modified)
        #expect(try FileManager.default.contentsOfDirectory(atPath: workspace.url("config/pwm").path) == ["presets.json"])
    }
}
