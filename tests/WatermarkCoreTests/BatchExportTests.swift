import Foundation
import PDFKit
import Testing
@testable import WatermarkCore

@Suite(.serialized)
struct BatchExportTests {
    func temporary() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    func item(_ root: URL, name: String = "document.pdf", fixture: String = "document.pdf") throws -> BatchItem {
        let source = Bundle.module.url(forResource: fixture, withExtension: nil, subdirectory: "Fixtures")!
        let target = root.appendingPathComponent(name)
        try FileManager.default.copyItem(at: source, to: target)
        var item = BatchItem(url: target)
        item.validation = .ready(try SourceValidation.inspect(item))
        return item
    }

    @Test func identityAndChangedSourceRecovery() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let original = try item(root)
        let hard = root.appendingPathComponent("hard.pdf"), link = root.appendingPathComponent("link.pdf")
        try FileManager.default.linkItem(at: original.url, to: hard)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: original.url)
        var collection = BatchCollection()
        #expect(collection.append([original.url, hard, link]) == 2)
        let distinct = try item(root, name: "other.pdf")
        #expect(collection.append([distinct.url]) == 0)
        let modified = Bundle.module.url(forResource: "scan.pdf", withExtension: nil, subdirectory: "Fixtures")!
        try Data(contentsOf: modified).write(to: original.url)
        #expect(throws: DocumentError.sourceChanged) {
            try SourceValidation.load(original.url, identity: original.identity, validated: original.validation.metadata)
        }
        #expect(try SourceValidation.inspect(BatchItem(url: original.url)).fingerprint != original.validation.metadata?.fingerprint)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: original.url.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: original.url.path) }
        #expect(throws: DocumentError.sourceUnavailable) { try SourceValidation.inspect(original) }
        try FileManager.default.removeItem(at: distinct.url)
        #expect(throws: DocumentError.sourceUnavailable) { try SourceValidation.inspect(distinct) }
    }

    @Test func safeNamesAndLateCollision() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let sourceItem = try item(root)
        let protected = try item(root, name: "document_watermarked.pdf")
        let protectedBytes = try Data(contentsOf: protected.url)
        let collision = root.appendingPathComponent("document_watermarked (2).pdf")
        var allocator = DestinationAllocator(directory: root, sources: [sourceItem.url, protected.url])
        let source = try SourceValidation.load(sourceItem.url, identity: sourceItem.identity, validated: sourceItem.validation.metadata)
        let saved = try BatchExport.save(source, watermark: WatermarkSettings(), settings: ExportSettings(), allocator: &allocator) { boundary in
            if case .beforePublication = boundary { try Data("race".utf8).write(to: collision, options: .withoutOverwriting) }
        }
        #expect(saved[0].lastPathComponent == "document_watermarked (3).pdf")
        #expect(try Data(contentsOf: collision) == Data("race".utf8))
        #expect(try Data(contentsOf: protected.url) == protectedBytes)
        #expect(try Data(contentsOf: sourceItem.url) == source.data)
        #expect(PDFDocument(url: saved[0])?.pageCount == 2)
        #expect(!((try FileManager.default.contentsOfDirectory(atPath: root.path)).contains { $0.hasPrefix(".passport-") }))
    }

    @Test func wholePageSeriesCancellationBoundaries() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let item = try item(root)
        let source = try SourceValidation.load(item.url, identity: item.identity, validated: item.validation.metadata)
        var settings = ExportSettings(); settings.format = .png
        for boundaryIndex in [0, 1, 2] {
            var allocator = DestinationAllocator(directory: root, sources: [item.url])
            #expect(throws: CancellationError.self) {
                try BatchExport.save(source, watermark: WatermarkSettings(), settings: settings, allocator: &allocator) { boundary in
                    switch boundary {
                    case .beforePage(let index) where index == boundaryIndex: throw CancellationError()
                    case .beforePublication where boundaryIndex == 2: throw CancellationError()
                    default: break
                    }
                }
            }
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["document.pdf"])
        }
        var allocator = DestinationAllocator(directory: root, sources: [item.url])
        let saved = try BatchExport.save(source, watermark: WatermarkSettings(), settings: settings, allocator: &allocator) { boundary in
            if case .afterPublication = boundary { throw CancellationError() }
        }
        #expect(saved.count == 2)
        #expect(saved.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
        #expect(saved[1].lastPathComponent == "document_page_002.png")
        let again = try BatchExport.save(source, watermark: WatermarkSettings(), settings: settings, allocator: &allocator)
        #expect(again[0].deletingLastPathComponent().lastPathComponent == "document_watermarked (2)")
    }

    @Test func allocatorRespectsFilesystemCollisionsAndReservations() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("passport_watermarked.pdf"), withIntermediateDirectories: false)
        var allocator = DestinationAllocator(directory: root, sources: [])
        let first = allocator.allocate(source: root.appendingPathComponent("passport.pdf"), format: .pdf, pageSeries: false)
        let second = allocator.allocate(source: root.appendingPathComponent("other/passport.pdf"), format: .pdf, pageSeries: false)
        #expect(first.lastPathComponent == "passport_watermarked (2).pdf")
        #expect(second.lastPathComponent == "passport_watermarked (3).pdf")
        let caseSensitive = try root.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey]).volumeSupportsCaseSensitiveNames ?? false
        try Data().write(to: root.appendingPathComponent("CASE_watermarked.png"))
        let lower = allocator.allocate(source: root.appendingPathComponent("case.png"), format: .png, pageSeries: false)
        #expect(lower.lastPathComponent == (caseSensitive ? "case_watermarked.png" : "case_watermarked (2).png"))
        let composed = "caf\u{00e9}"
        let decomposed = "cafe\u{0301}"
        try FileManager.default.createDirectory(at: root.appendingPathComponent(composed + "_watermarked"), withIntermediateDirectories: false)
        let unicode = allocator.allocate(source: root.appendingPathComponent(decomposed + ".pdf"), format: .png, pageSeries: true)
        #expect(unicode.lastPathComponent.hasSuffix(" (2)"))
    }

    @Test func runContinuesAfterFailureAndCountsExcludedRows() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let first = try item(root, name: "first.pdf")
        let second = try item(root, name: "second.pdf")
        var invalid = BatchItem(url: root.appendingPathComponent("corrupt.pdf")); invalid.validation = .invalid("Unreadable")
        let result = await BatchExport.run(items: [first, invalid, second], watermark: WatermarkSettings(), policy: .original,
            settings: ExportSettings(), destination: root, boundary: { id, boundary in
                if id == first.id, case .beforeInput = boundary { throw DocumentError.writeFailed }
            }, update: { _, _, _ in })
        #expect(result.saved == 1 && result.failed == 2 && result.unprocessed == 0)
        let empty = await BatchExport.run(items: [invalid], watermark: WatermarkSettings(), policy: .original,
            settings: ExportSettings(), destination: root, update: { _, _, _ in })
        #expect(empty.saved == 0 && empty.failed == 1)
        let task = Task.detached {
            await BatchExport.run(items: [first, second], watermark: WatermarkSettings(), policy: .original,
                settings: ExportSettings(), destination: root, boundary: { _, boundary in
                    if case .afterPublication = boundary { withUnsafeCurrentTask { $0?.cancel() } }
                }, update: { _, _, _ in })
        }
        let cancelled = await task.value
        #expect(cancelled.saved == 1 && cancelled.unprocessed == 1 && cancelled.cancelled)
    }
}
