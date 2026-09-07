import Testing
import SwiftUI
import PDFKit
@testable import PassportFiligrane
import WatermarkCore

@Suite(.serialized) @MainActor
struct SessionTests {
    func fixture(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WatermarkCoreTests/Fixtures/\(name)")
    }

    func wait(_ condition: @MainActor () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(20)
        while !condition() && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try #require(condition())
    }

    @Test func defaultsAppendSelectionAndNavigation() async throws {
        let session = Session()
        #expect(!session.canExport)
        #expect(session.outputPolicy == .original)
        #expect(session.exportSettings.flattened && session.exportSettings.dpi == 450)
        session.add([fixture("document.pdf"), fixture("photo.jpg")])
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.preview != nil && session.pageCount == 2)
        let first = session.selected!.id
        session.watermark.text = "MY COPY"
        session.outputPolicy = .png
        session.setZoom(2)
        session.changePage(1)
        try await wait { !session.isRendering }
        #expect(session.pageIndex == 1 && session.zoom == 2)
        session.changePage(1)
        #expect(session.pageIndex == 1)
        #expect(session.displayedKey?.page == 1)
        session.select(session.batch.items[1].id)
        #expect(session.preview == nil)
        try await wait { !session.isRendering }
        #expect(session.pageIndex == 0 && session.zoom == nil)
        #expect(session.outputPolicy == .png && session.watermark.text == "MY COPY")
        session.add([fixture("transparent.png"), fixture("document.pdf")])
        try await wait { !session.isLoading }
        #expect(session.batch.items.count == 3)
        #expect(session.selected?.id != first && session.feedback.contains("already added"))
        session.remove(session.selected!.id)
        #expect(session.selected?.url == fixture("transparent.png"))
        session.clearAll()
        #expect(session.preview == nil && !session.canExport)
        #expect(session.watermark.text == "MY COPY" && session.outputPolicy == .png)
    }

    @Test func staleWorkAndRemovalDuringValidation() async throws {
        let session = Session()
        session.add([fixture("document.pdf"), fixture("photo.jpg"), fixture("corrupt.pdf"), fixture("pages-10.pdf")])
        session.remove(session.batch.items[1].id)
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.batch.items.count == 3)
        for index in 0..<20 {
            session.select(session.batch.items[index % 2 == 0 ? 0 : 2].id)
            session.watermark.text = "VALUE \(index)"
            session.setZoom(index % 2 == 0 ? 0.5 : 1)
            session.changePage(1)
        }
        try await wait { !session.isRendering }
        #expect(session.displayedKey?.itemID == session.selected?.id)
        #expect(session.displayedKey?.watermark.text == "VALUE 19")
        #expect(session.displayedKey?.page == 1)
        session.select(session.batch.items[1].id)
        #expect(session.preview == nil)
        #expect(session.canExport)
        session.clearAll()
        session.add([fixture("opaque.png")])
        session.clearAll()
        session.add([fixture("transparent.png")])
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.batch.items.count == 1 && session.selected?.url == fixture("transparent.png"))
    }

    @Test func exportSnapshotsMutationGuardsCancellationAndRecovery() async throws {
        let session = Session()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        session.add([fixture("document.pdf"), fixture("opaque.png")])
        try await wait { !session.isLoading && !session.isRendering }
        session.exportSettings.flattened = false
        session.watermark.text = "LATEST EXPORT"
        session.startExport(to: directory)
        #expect(session.isExporting && !session.canExport)
        session.watermark.text = "IGNORED"
        session.outputPolicy = .jpg
        session.clearAll()
        session.add([fixture("photo.jpg")])
        session.select(session.batch.items[1].id)
        try await wait { !session.isExporting && !session.isRendering }
        #expect(session.batch.items.count == 2)
        #expect(session.watermark.text == "LATEST EXPORT" && session.outputPolicy == .original)
        #expect(session.summary?.saved == 2 && session.summary?.failed == 0)
        #expect(PDFDocument(url: directory.appendingPathComponent("document_watermarked.pdf"))?.string?.contains("LATEST EXPORT") == true)
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("opaque_watermarked.png").path))
        session.startExport(to: directory.appendingPathComponent("missing"))
        try await wait { !session.isExporting }
        #expect(session.summary?.failed == 2 && session.summary?.saved == 0)
        #expect(session.canExport)
        session.startExport(to: directory)
        session.cancelExport()
        #expect(session.isCancelling)
        try await wait { !session.isExporting }
        #expect(session.summary?.cancelled == true)
        #expect(session.summary?.saved == 0 && session.summary?.unprocessed == 2)
        session.startExport(to: directory)
        try await wait { !session.isExporting }
        #expect(session.summary?.saved == 2)
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("document_watermarked (2).pdf").path))
    }

    @Test func changedSourceNeverUsesCachedPreview() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("input.pdf")
        try Data(contentsOf: fixture("document.pdf")).write(to: url)
        let session = Session()
        session.add([url])
        try await wait { !session.isLoading && !session.isRendering }
        try Data(contentsOf: fixture("scan.pdf")).write(to: url)
        session.watermark.opacity = 50
        try await wait { !session.isRendering }
        #expect(session.preview == nil && !session.canExport)
        if case .invalid(let message) = session.selected?.validation { #expect(message.contains("add this file again")) }
        else { Issue.record("Changed source should require re-addition") }
        session.clearAll()
        session.add([url])
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.canExport && session.preview != nil)
        try Data("corrupt replacement".utf8).write(to: url)
        session.setZoom(1)
        try await wait { !session.isRendering }
        #expect(session.preview == nil && !session.canExport)
        if case .invalid(let message) = session.selected?.validation {
            #expect(message == DocumentError.sourceChanged.localizedDescription)
        } else { Issue.record("Corrupt replacement should require re-addition") }
    }

    @Test func previewCompletesWhileExportWorkerIsBlocked() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let session = Session()
        session.add([fixture("pages-50.pdf"), fixture("photo.jpg")])
        try await wait { !session.isLoading && !session.isRendering }
        let gate = DispatchSemaphore(value: 0)
        session.exportBoundary = { _, boundary in
            if case .beforePage(0) = boundary { _ = gate.wait(timeout: .now() + 10) }
        }
        defer { gate.signal(); gate.signal() }
        session.startExport(to: root)
        session.select(session.batch.items[1].id)
        try await wait { session.preview != nil && !session.isRendering }
        #expect(session.isExporting)
        #expect(session.displayedKey?.itemID == session.selected?.id)
        session.cancelExport()
        #expect(session.isCancelling)
        gate.signal()
        try await wait { !session.isExporting }
        #expect(session.summary?.cancelled == true)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"] != nil))
    func renderNativeInterface() async throws {
        let output = ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"]!
        let session = Session()
        session.add([fixture("photo.jpg"), fixture("document.pdf")])
        try await wait { !session.isLoading && !session.isRendering }
        _ = NSApplication.shared
        NSApplication.shared.delegate = TestingAppDelegate.shared
        let view = NSHostingView(rootView: ContentView(session: session).frame(width: 1040, height: 720))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 720),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        try await Task.sleep(for: .milliseconds(300))
        try await wait { !session.isRendering }
        #expect(session.canExport)
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        let rep = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        let bytes = try #require(rep.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
        try bytes.write(to: URL(fileURLWithPath: output).appendingPathComponent("native-interface.png"))
    }
}

@MainActor private final class TestingAppDelegate: NSObject, NSApplicationDelegate {
    static let shared = TestingAppDelegate()
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
