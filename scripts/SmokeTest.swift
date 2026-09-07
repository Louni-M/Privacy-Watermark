import AppKit
import SwiftUI
import PDFKit
import WatermarkCore

@main struct SmokeTest {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = SmokeDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor final class SmokeDelegate: NSObject, NSApplicationDelegate {
    let session = Session()
    var window: NSWindow!
    var completed: [String] = []
    let fixtures = URL(fileURLWithPath: CommandLine.arguments[1])
    let output = URL(fileURLWithPath: CommandLine.arguments[2])

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 720),
                          styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(session: session))
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        Task {
            do {
                try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
                try await runChecks()
                finish(error: nil)
            } catch { finish(error: String(describing: error)) }
        }
        Task {
            try? await Task.sleep(for: .seconds(45))
            finish(error: "Smoke test exceeded 45 seconds")
        }
    }

    func wait(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(10)
        while !condition() && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try check(condition(), "Operation completed before timeout")
    }

    func check(_ value: Bool, _ message: String) throws {
        if !value { throw NSError(domain: "NativeSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    }

    func cancelPanel(_ operation: @escaping @MainActor () async -> Void) async throws {
        let task = Task { await operation() }
        try await wait { session.activePanel != nil }
        session.activePanel?.cancel(nil)
        await task.value
    }

    func runChecks() async throws {
        try check(!session.canExport, "Empty window disables export")
        try await cancelPanel { await self.session.chooseFile() }
        try check(session.document == nil && !session.canExport, "Cancelling initial Open leaves the empty state")
        completed.append("Cancel native Open in empty state")

        session.load(fixtures.appendingPathComponent("document.pdf"))
        try await wait { !session.isLoading && !session.isRendering }
        try check(session.preview != nil && session.document?.pageCount == 2, "PDF first-page preview")
        try check(session.exportSettings.flattened && session.exportSettings.dpi == 450, "Flattened 450 DPI default")
        completed.append("Load and preview PDF with native default")
        try await cancelPanel { await self.session.chooseFile() }
        try check(session.document?.kind == .pdf, "Cancelling replacement keeps source")
        try await cancelPanel { await self.session.chooseDestination() }
        try check(!session.isExporting && session.status.isEmpty, "Cancelling Save writes nothing")
        completed.append("Cancel replacement Open and native Save")

        let saveSelection = Task { await session.chooseDestination() }
        try await wait { session.activePanel != nil }
        try check(session.activePanel?.nameFieldStringValue == "export_filigree.pdf", "Default output filename")
        session.activePanel?.directoryURL = output
        session.activePanel?.nameFieldStringValue = "panel-copy.pdf"
        try await Task.sleep(for: .milliseconds(250))
        session.activePanel?.ok(nil)
        await saveSelection.value
        try await wait { !session.isExporting }
        try check(PDFDocument(url: output.appendingPathComponent("panel-copy.pdf"))?.pageCount == 2, "Save panel destination reaches export")
        completed.append("Choose native Save destination and export")

        let pdf = output.appendingPathComponent("smoke.pdf")
        session.startExport(to: pdf, replace: true)
        try await wait { !session.isExporting }
        try check(session.errorMessage == nil && PDFDocument(url: pdf)?.pageCount == 2, "Flattened PDF export")
        completed.append("Export and reopen flattened PDF")
        session.exportSettings.format = .png
        try await cancelPanel { await self.session.chooseDestination() }
        try check(!session.isExporting, "Cancel native folder panel")
        session.startExport(to: output, replace: true)
        try await wait { !session.isExporting }
        try check(session.errorMessage == nil && FileManager.default.fileExists(atPath: output.appendingPathComponent("document_page_002.png").path), "Page-series export")
        completed.append("Cancel folder panel and export page images")

        session.load(fixtures.appendingPathComponent("photo.jpg"))
        try await wait { !session.isLoading && !session.isRendering }
        try check(session.document?.kind == .image && session.preview != nil, "Image preview")
        session.exportSettings.format = .png
        session.startExport(to: output.appendingPathComponent("photo.png"), replace: true)
        try await wait { !session.isExporting }
        try check(session.errorMessage == nil, "Image export")
        completed.append("Load, preview, and export image")

        try await Task.sleep(for: .milliseconds(200))
        if let view = window.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            try rep.representation(using: .png, properties: [:])?.write(to: output.appendingPathComponent("window.png"))
        }
    }

    func finish(error: String?) {
        let report: [String: Any] = ["passed": error == nil, "checks": completed,
            "error": error ?? "", "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "architecture": targetArchitecture]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: output.appendingPathComponent("smoke.json"))
        }
        exit(error == nil ? 0 : 1)
    }

    var targetArchitecture: String {
        #if arch(arm64)
        "arm64"
        #else
        "x86_64"
        #endif
    }
}
