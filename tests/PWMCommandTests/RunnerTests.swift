import Foundation
import ImageIO
import PDFKit
import Testing
@testable import PWMCommand
import WatermarkCore

@Suite(.serialized)
struct RunnerTests {
    let secret = "SECRET Ünïque — 4242"

    func staging(in folder: URL) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []).filter { $0.hasPrefix(".passport-batch-") }
    }

    @Test func copiesAreWrittenBesideEachSourceAndOriginalsStayUnchanged() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("Documents/passport.jpg"), scan = try workspace.image("Scans/scan.png")
        let contract = try workspace.pdf("Scans/contract.pdf")
        let hashes = try [photo, scan, contract].map(sha256)

        let run = await runCommand([secret, photo.path, scan.path, "--date", contract.path])
        #expect(run.status == .success)
        #expect(run.output == [workspace.url("Documents/passport_watermarked.jpg").path,
                               workspace.url("Scans/scan_watermarked.png").path,
                               workspace.url("Scans/contract_watermarked.pdf").path])
        #expect(run.errors == ["3 saved · 0 failed · 0 excluded · 0 not processed"])
        #expect(try [photo, scan, contract].map(sha256) == hashes)
        #expect(PDFDocument(url: workspace.url("Scans/contract_watermarked.pdf"))?.pageCount == 2)
        #expect(staging(in: workspace.url("Documents")).isEmpty && staging(in: workspace.url("Scans")).isEmpty)
    }

    @Test func relativePathsResolveAgainstTheCurrentDirectory() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        try workspace.image("in/a.jpg")
        try workspace.folder("out")
        let run = await runCommand(["COPY", "in/a.jpg", "--out", "out"], in: workspace.root)
        #expect(run.status == .success && run.output == [workspace.url("out/a_watermarked.jpg").path])
    }

    @Test func outputFolderMustExistAndBeWritable() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/a.jpg"), other = try workspace.image("elsewhere/b.png")
        let out = try workspace.folder("out")

        let run = await runCommand(["COPY", photo.path, other.path, "-o", out.path])
        #expect(run.status == .success)
        #expect(run.output == [out.appendingPathComponent("a_watermarked.jpg").path, out.appendingPathComponent("b_watermarked.png").path])

        let before = workspace.listing()
        let file = workspace.url("in/a.jpg").path
        let locked = try workspace.folder("locked")
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: locked.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: locked.path) }
        for target in [workspace.url("missing").path, file, locked.path] {
            let refused = await runCommand(["COPY", photo.path, "--out", target])
            #expect(refused.status == .usage && refused.output.isEmpty)
            #expect(refused.errorText.contains(target) && refused.errorText.contains("--help"))
        }
        #expect(workspace.listing() == (before + ["locked"]).sorted())
    }

    @Test func existingNamesGetANumberAndAreNeverReplaced() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/passport.jpg")
        let existing = try workspace.text("in/passport_watermarked.jpg", "keep me")
        let run = await runCommand(["COPY", photo.path])
        #expect(run.status == .success && run.output == [workspace.url("in/passport_watermarked (2).jpg").path])
        #expect(try String(contentsOf: existing, encoding: .utf8) == "keep me")
        let again = await runCommand(["COPY", photo.path])
        #expect(again.output == [workspace.url("in/passport_watermarked (3).jpg").path])
    }

    @Test func pdfAsImagesIsPublishedAsOnePageFolder() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let lease = try workspace.pdf("in/lease.pdf", pages: 3)
        let run = await runCommand(["COPY", lease.path, "--format", "png"])
        let folder = workspace.url("in/lease_watermarked")
        #expect(run.status == .success && run.output == [folder.path])
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted()
            == ["lease_page_001.png", "lease_page_002.png", "lease_page_003.png"])
    }

    @Test func theSameFileThroughALinkIsProcessedOnce() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/id.jpg")
        let link = workspace.url("in/link.jpg")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: photo)
        let run = await runCommand(["COPY", photo.path, link.path, photo.path])
        #expect(run.status == .success && run.output == [workspace.url("in/id_watermarked.jpg").path])
        #expect(run.errors.last == "1 saved · 0 failed · 0 excluded · 0 not processed")
        #expect(!FileManager.default.fileExists(atPath: workspace.url("in/link_watermarked.jpg").path))
    }

    @Test func partialRunsReportExclusionsAndExitWithOne() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/a.jpg"), notes = try workspace.text("in/notes.txt")
        let locked = try workspace.pdf("in/b.pdf", password: "pw")
        let folder = try workspace.folder("in/folder"), missing = workspace.url("in/missing.jpg")

        let run = await runCommand([secret, photo.path, notes.path, locked.path, folder.path, missing.path])
        #expect(run.status == .partial)
        #expect(run.output == [workspace.url("in/a_watermarked.jpg").path])
        #expect(run.errors.contains("Excluded: \(notes.path) — Choose a JPG, PNG, or PDF file."))
        #expect(run.errors.contains("Excluded: \(locked.path) — This PDF is password-protected and cannot be opened."))
        #expect(run.errors.contains { $0.hasPrefix("Excluded: \(folder.path)") })
        #expect(run.errors.contains { $0.hasPrefix("Excluded: \(missing.path) — This file is unavailable") })
        #expect(run.errors.last == "1 saved · 0 failed · 4 excluded · 0 not processed")
        #expect(!run.errorText.contains("SECRET") && !run.output.joined().contains("SECRET"))
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test func failuresDoNotStopTheRemainingInputs() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let first = try workspace.image("in/a.jpg"), second = try workspace.image("in/b.jpg"), third = try workspace.image("in/c.jpg")
        let calls = Lines()
        let run = await runCommand([secret, first.path, second.path, third.path]) { _, boundary in
            guard case .beforeInput = boundary else { return }
            calls.append("input")
            if calls.all.count == 2 { throw DocumentError.writeFailed }
        }
        #expect(run.status == .partial)
        #expect(run.output == [workspace.url("in/a_watermarked.jpg").path, workspace.url("in/c_watermarked.jpg").path])
        #expect(run.errors.contains("Failed: \(second.path) — Unable to save the output. Check the destination and available disk space."))
        #expect(run.errors.last == "2 saved · 1 failed · 0 excluded · 0 not processed")
        #expect(!run.errorText.contains("SECRET"))
    }

    @Test func nothingSavedExitsWithTwo() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let notes = try workspace.text("in/notes.txt"), empty = try workspace.text("in/empty.pdf", "")
        let run = await runCommand([secret, notes.path, empty.path])
        #expect(run.status == .nothingSaved && run.output.isEmpty)
        #expect(run.errors.last == "0 saved · 0 failed · 2 excluded · 0 not processed")
        #expect(!run.errorText.contains("SECRET"))
        #expect(workspace.listing() == ["in", "in/empty.pdf", "in/notes.txt"])
    }

    @Test func cancellingAtAPageBoundaryKeepsCompletedCopiesOnly() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let first = try workspace.image("in/a.jpg"), lease = try workspace.pdf("in/lease.pdf", pages: 3)
        let third = try workspace.image("in/c.jpg")
        let run = await Task {
            await runCommand(["COPY", first.path, lease.path, third.path]) { _, boundary in
                // Simulates Control-C while the second input is on its second page.
                if case .beforePage(1) = boundary { withUnsafeCurrentTask { $0?.cancel() } }
            }
        }.value
        #expect(run.status == .interrupted)
        #expect(run.output == [workspace.url("in/a_watermarked.jpg").path])
        #expect(Array(run.errors.suffix(2)) == ["pwm: interrupted.", "1 saved · 0 failed · 0 excluded · 2 not processed"])
        #expect(workspace.listing() == ["in", "in/a.jpg", "in/a_watermarked.jpg", "in/c.jpg", "in/lease.pdf"])
    }

    @Test func cancellingBeforeExportCountsEveryInputAsNotProcessed() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/a.jpg"), notes = try workspace.text("in/notes.txt")
        let task = Task { await runCommand(["COPY", photo.path, notes.path]) }
        task.cancel()
        let run = await task.value
        #expect(run.status == .interrupted && run.output.isEmpty)
        #expect(run.errors.last == "0 saved · 0 failed · 0 excluded · 2 not processed")
        #expect(workspace.listing() == ["in", "in/a.jpg", "in/notes.txt"])
    }

    @Test func stripOnlyRemovesMetadataAndKeepsPixels() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let photo = try workspace.image("in/IMG_0042.jpg", width: 640, height: 480, gps: true)
        let png = try workspace.image("in/screen.png", width: 300, height: 120, gps: true)
        let original = try properties(photo)
        #expect(original[kCGImagePropertyGPSDictionary] != nil, "fixture must carry GPS")
        let hash = try sha256(photo)

        let run = await runCommand(["--strip-only", photo.path, png.path])
        #expect(run.status == .success)
        let stripped = workspace.url("in/IMG_0042_stripped.jpg"), strippedPNG = workspace.url("in/screen_stripped.png")
        #expect(run.output == [stripped.path, strippedPNG.path])
        for (url, size) in [(stripped, (640, 480)), (strippedPNG, (300, 120))] {
            let values = try properties(url)
            #expect(values[kCGImagePropertyPixelWidth] as? Int == size.0 && values[kCGImagePropertyPixelHeight] as? Int == size.1)
            #expect(values[kCGImagePropertyGPSDictionary] == nil)
            #expect((values[kCGImagePropertyTIFFDictionary] as? [CFString: Any])?[kCGImagePropertyTIFFMake] == nil)
            #expect((values[kCGImagePropertyExifDictionary] as? [CFString: Any])?[kCGImagePropertyExifDateTimeOriginal] == nil)
        }
        #expect(try sha256(photo) == hash)
    }

    @Test func stripOnlyExcludesPDFsAndRejectsWatermarkOptions() async throws {
        let workspace = try Workspace(); defer { workspace.remove() }
        let report = try workspace.pdf("in/report.pdf")
        let run = await runCommand(["--strip-only", report.path])
        #expect(run.status == .nothingSaved && run.output.isEmpty)
        #expect(run.errors.first == "Excluded: \(report.path) — \(Runner.stripPDFReason)")
        #expect(workspace.listing() == ["in", "in/report.pdf"])

        for option in [["--opacity", "20"], ["--format", "png"], ["--preset", "rental"], ["--date"], ["--pdf-mode", "text"]] {
            let refused = await runCommand(["--strip-only", report.path] + option)
            #expect(refused.status == .usage && refused.errorText.contains("\(option[0]) cannot be combined with --strip-only"))
        }
    }

    func properties(_ url: URL) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }
}
