import Foundation
import Testing
@testable import PWMCommand
import WatermarkCore

/// Runs the built `pwm` binary, as Finder and scripts do, and compares its
/// copies with the app's own `Processing.export` for the same settings.
@Suite(.serialized)
struct EndToEndTests {
    let text = "Dossier location — Agence Hôtel-de-Ville"

    /// `scripts/test.sh` builds `pwm` into the same products folder as the test bundle.
    func binary() throws -> URL {
        let products = Bundle(for: Lines.self).bundleURL.deletingLastPathComponent()
        let url = products.appendingPathComponent("pwm")
        try #require(FileManager.default.isExecutableFile(atPath: url.path),
                     "Build pwm first (scripts/test.sh does): \(url.path)")
        return url
    }

    /// A minimal environment like Automator's: C locale, no login PATH, no presets.
    func launch(_ arguments: [String], workspace: Workspace) throws -> (Int32, [String], String) {
        let process = Process()
        process.executableURL = try binary()
        process.arguments = arguments
        process.environment = ["LC_ALL": "C", "PATH": "/usr/bin:/bin", "HOME": workspace.url("home").path]
        let output = Pipe(), errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        try process.run()
        let out = output.fileHandleForReading.readDataToEndOfFile()
        let err = errors.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let lines = String(decoding: out, as: UTF8.self).split(separator: "\n").map(String.init)
        return (process.terminationStatus, lines, String(decoding: err, as: UTF8.self))
    }

    /// The app's export of one source into a scratch folder.
    func appExport(_ source: URL, watermark: WatermarkSettings, policy: OutputPolicy, settings: ExportSettings,
                   into folder: URL) throws -> [URL] {
        let document = try SourceDocument.load(source)
        let resolved = policy.resolve(for: source, settings: settings)
        let series = document.kind == .pdf && resolved.format != .pdf
        let destination = folder.appendingPathComponent(series ? "pages" : "app.\(resolved.format.fileExtension)", isDirectory: series)
        if series { try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true) }
        return try Processing.export(document, watermark: watermark, settings: resolved, destination: destination)
    }

    @Test func accentedTextUnderCLocaleMatchesTheAppExport() throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/id.jpg", gps: true), scan = try workspace.image("in/scan.png")
        let payslip = try workspace.pdf("other/payslip.pdf", pages: 2)
        let hashes = try [photo, scan, payslip].map(sha256)

        let (status, output, errors) = try launch([text, photo.path, scan.path, payslip.path, "--date"], workspace: workspace)
        #expect(status == 0, "\(errors)")
        let saved = [workspace.url("in/id_watermarked.jpg"), workspace.url("in/scan_watermarked.png"),
                     workspace.url("other/payslip_watermarked.pdf")]
        #expect(output == saved.map(\.path))
        #expect(errors == "3 saved · 0 failed · 0 excluded · 0 not processed\n")
        #expect(try [photo, scan, payslip].map(sha256) == hashes)

        var watermark = WatermarkSettings()
        watermark.text = text + "\n" + WatermarkText.dateLine(for: Date())
        for (source, copy) in zip([photo, scan, payslip], saved) {
            let expected = try appExport(source, watermark: watermark, policy: .original, settings: ExportSettings(),
                                         into: try workspace.folder("app/\(source.lastPathComponent)"))
            #expect(try Data(contentsOf: copy) == Data(contentsOf: expected[0]), "\(copy.lastPathComponent) differs from the app")
        }
    }

    @Test func optionsAndPageImagesMatchTheAppExport() throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let lease = try workspace.pdf("in/lease.pdf", pages: 3)
        let arguments = [text, lease.path, "--opacity", "55", "--size", "48", "--spacing", "90", "--color", "gray",
                         "--direction", "down", "--format", "jpg", "--dpi", "300"]
        let (status, output, errors) = try launch(arguments, workspace: workspace)
        let folder = workspace.url("in/lease_watermarked")
        #expect(status == 0 && output == [folder.path], "\(errors)")

        var watermark = WatermarkSettings()
        watermark.text = text
        watermark.opacity = 55; watermark.size = 48; watermark.spacing = 90
        watermark.color = .gray; watermark.direction = .descending
        var settings = ExportSettings()
        settings.dpi = 300
        let expected = try appExport(lease, watermark: watermark, policy: .jpg, settings: settings, into: try workspace.folder("app"))
        #expect(expected.map(\.lastPathComponent) == ["lease_page_001.jpg", "lease_page_002.jpg", "lease_page_003.jpg"])
        for page in expected {
            #expect(try Data(contentsOf: folder.appendingPathComponent(page.lastPathComponent)) == Data(contentsOf: page))
        }
    }

    @Test func exitCodesFromTheBinary() throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/a.jpg"), notes = try workspace.text("in/notes.txt")
        #expect(try launch(["--help"], workspace: workspace).0 == 0)
        #expect(try launch(["COPY", photo.path, "--opacity", "150"], workspace: workspace).0 == 64)
        #expect(try launch(["--preset", "x", photo.path], workspace: workspace).0 == 78)
        let partial = try launch(["COPY", photo.path, notes.path], workspace: workspace)
        #expect(partial.0 == 1 && partial.1.count == 1)
        #expect(try launch(["COPY", notes.path], workspace: workspace).0 == 2)
    }
}
