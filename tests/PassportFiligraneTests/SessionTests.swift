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
        let deadline = ContinuousClock.now + .seconds(10)
        while !condition() && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try #require(condition())
    }

    @Test func defaultsAndFileSwitching() async throws {
        let session = Session()
        #expect(!session.canExport)
        #expect(session.exportSettings.flattened)
        #expect(session.exportSettings.dpi == 450)
        session.load(fixture("document.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.preview != nil)
        #expect(session.document?.pageCount == 2)
        #expect(session.exportSettings.format == .pdf)
        session.watermark.text = "MY COPY"
        session.exportSettings.dpi = 600
        session.load(fixture("photo.jpg"))
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.document?.kind == .image)
        #expect(session.exportSettings.format == .jpg)
        #expect(session.exportSettings.dpi == 600)
        #expect(session.watermark.text == "MY COPY")
    }

    @Test func staleLoadsAndPreviewsDoNotReplaceLatestState() async throws {
        let session = Session()
        session.load(fixture("document.pdf"))
        session.load(fixture("photo.jpg"))
        session.watermark.text = "DURING LOAD"
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.document?.kind == .image)
        for i in 0..<20 { session.watermark.text = "VALUE \(i)" }
        session.load(fixture("document.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.document?.kind == .pdf)
        #expect(session.watermark.text == "VALUE 19")
        #expect(session.preview != nil)
        #expect(session.errorMessage == nil)
    }

    @Test func invalidReplacementPreservesUsableDocumentAndRecovers() async throws {
        let session = Session()
        session.load(fixture("photo.jpg"))
        try await wait { !session.isLoading && !session.isRendering }
        session.load(fixture("corrupt.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.errorMessage != nil)
        #expect(session.document?.kind == .image)
        #expect(session.canExport)
        session.load(fixture("document.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        #expect(session.errorMessage == nil)
        #expect(session.document?.kind == .pdf)
    }

    @Test func exportLatestSettingsAndRecoverAfterFailure() async throws {
        let session = Session()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        session.load(fixture("document.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        session.exportSettings.flattened = false
        session.watermark.text = "LATEST EXPORT"
        session.startExport(to: directory.appendingPathComponent("copy.pdf"))
        #expect(session.isExporting)
        #expect(!session.canExport)
        try await wait { !session.isExporting }
        #expect(session.errorMessage == nil)
        #expect(PDFDocument(url: directory.appendingPathComponent("copy.pdf"))?.string?.contains("LATEST EXPORT") == true)
        session.startExport(to: directory.appendingPathComponent("missing/copy.pdf"))
        try await wait { !session.isExporting }
        #expect(session.errorMessage != nil)
        #expect(session.canExport)
        #expect(session.status.isEmpty)
        session.startExport(to: directory.appendingPathComponent("recovered.pdf"))
        try await wait { !session.isExporting }
        #expect(session.errorMessage == nil)
        #expect(!session.status.isEmpty)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"] != nil))
    func renderNativeInterface() async throws {
        guard let output = ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"] else { return }
        let session = Session()
        session.load(fixture("photo.jpg"))
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
        try await Task.sleep(for: .milliseconds(250))
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
