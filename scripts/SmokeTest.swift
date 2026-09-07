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
        DispatchQueue.main.async { delegate.start() }
        DispatchQueue.global().asyncAfter(deadline: .now() + 300) { exit(124) }
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor final class SmokeDelegate: NSObject, NSApplicationDelegate {
    let session = Session()
    var window: NSWindow!
    var completed: [String] = [] {
        didSet {
            FileHandle.standardError.write(Data("SMOKE: \(completed.last ?? "")\n".utf8))
        }
    }
    var started = false
    let fixtures = URL(fileURLWithPath: CommandLine.arguments[1])
    let output = URL(fileURLWithPath: CommandLine.arguments[2])

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDidFinishLaunching(_ notification: Notification) {
        start()
    }

    func start() {
        guard !started else { return }
        started = true
        FileHandle.standardError.write(Data("SMOKE: starting native window\n".utf8))
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
            try? await Task.sleep(for: .seconds(240))
            finish(error: "Smoke test exceeded 240 seconds")
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
        // The completion fires before the sheet's dismissal animation finishes.
        // A human cannot open another panel until AppKit releases the parent.
        try await Task.sleep(for: .milliseconds(400))
    }

    func runChecks() async throws {
        if ProcessInfo.processInfo.environment["PASSPORT_BATCH_CORPUS"] != nil { try await measureBatch(); return }
        try check(!session.canExport, "Empty window disables export")
        try await cancelPanel { await self.session.chooseFiles() }
        try check(session.batch.items.isEmpty && !session.canExport, "Cancelled Add leaves the empty state")
        completed.append("Programmatic cancellation of native Add files panel")

        let localSource = output.appendingPathComponent("document.pdf")
        try Data(contentsOf: fixtures.appendingPathComponent("document.pdf")).write(to: localSource)
        session.add([localSource, fixtures.appendingPathComponent("photo.jpg"),
            fixtures.appendingPathComponent("transparent.png"), fixtures.appendingPathComponent("corrupt.pdf")])
        try await wait { !session.isLoading && !session.isRendering }
        try check(session.preview != nil && session.pageCount == 2, "PDF first-page preview")
        try check(session.exportSettings.flattened && session.exportSettings.dpi == 450 && session.outputPolicy == .original, "Shared defaults")
        completed.append("Programmatic mixed batch import, invalid row and first-page preview in native window")
        try await cancelPanel { await self.session.chooseFiles() }
        try await cancelPanel { await self.session.chooseDestination() }
        try check(!session.isExporting && session.status.isEmpty && session.batch.items.count == 4, "Cancelled panels preserve batch")
        completed.append("Programmatic Add and destination-folder panel cancellation")

        session.setZoom(2)
        session.changePage(1)
        try await wait { !session.isRendering }
        try check(session.pageIndex == 1 && session.zoom == 2, "Page change preserves zoom")
        session.updateViewport(size: CGSize(width: 500, height: 450),
            region: CGRect(x: 40, y: 20, width: 200, height: 150), backingScale: 2)
        try await wait { !session.isRendering }
        session.setZoom(nil)
        session.watermark.color = .black
        session.watermark.direction = .descending
        try await wait { !session.isRendering }
        completed.append("Programmatic page navigation, zoom, viewport pan, Fit and shared settings")
        session.select(session.batch.items[1].id)
        try await wait { !session.isRendering }
        try check(session.pageIndex == 0 && session.zoom == nil, "Selection resets page and Fit")
        session.add([localSource])
        try check(session.batch.items.count == 4 && session.feedback.contains("already added"), "Duplicate ignored")
        session.remove(session.batch.items.last!.id)
        try check(session.batch.items.count == 3, "Individual removal")
        completed.append("Programmatic selection, duplicate addition and removal")

        session.startExport(to: output)
        try await wait { !session.isExporting }
        try check(session.summary?.saved == 3 && session.summary?.failed == 0, "Mixed original-format export")
        let savedPDF = session.batch.items.compactMap { item -> URL? in
            if case .saved(let urls) = item.export { return urls.first { $0.pathExtension == "pdf" } }
            return nil
        }.first!
        try check(PDFDocument(url: savedPDF)?.pageCount == 2, "Independent PDF reopen")
        completed.append("Mixed original-format export and PDFKit reopen")

        session.outputPolicy = .png
        session.startExport(to: output)
        try await wait { !session.isExporting }
        try check(session.summary?.saved == 3, "PNG batch export")
        if case .saved(let urls) = session.batch.items[0].export {
            try check(urls.count == 2 && urls[1].lastPathComponent == "document_page_002.png", "Dedicated numbered page folder")
        } else { try check(false, "PDF page folder saved") }
        session.startExport(to: output.appendingPathComponent("missing"))
        try await wait { !session.isExporting }
        try check(session.summary?.failed == 3 && session.summary?.saved == 0, "Per-input failures")
        session.startExport(to: output)
        session.cancelExport()
        try check(session.isCancelling, "Immediate cancellation acknowledgement")
        try await wait { !session.isExporting }
        try check(session.summary?.cancelled == true && session.summary?.unprocessed == 3, "Cancellation summary")
        completed.append("Page-folder export, write failure, cancellation and summary")

        for (name, width, height) in [("window", 1040.0, 720.0), ("minimum-window", 860.0, 600.0)] {
            window.setContentSize(CGSize(width: width, height: height))
            try await Task.sleep(for: .milliseconds(300))
            try await wait { !session.isRendering }
            if let view = window.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                try rep.representation(using: .png, properties: [:])?.write(to: output.appendingPathComponent("\(name).png"))
            }
        }
        completed.append("Captured normal and minimum-size native layouts; manual drag-and-drop remains pending")
    }

    func measureBatch() async throws {
        let environment = ProcessInfo.processInfo.environment
        let root = URL(fileURLWithPath: environment["PASSPORT_BATCH_CORPUS"]!)
        let count = Int(environment["PASSPORT_BATCH_COUNT"] ?? "100")!
        let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("manifest.json"))) as! [String: Any]
        let records = (manifest["files"] as! [[String: Any]]).filter { count == 100 || $0["subset"] as? Bool == true }
        let urls = records.map { root.appendingPathComponent($0["name"] as! String) }
        func elapsed(_ start: ContinuousClock.Instant) -> Double {
            let value = start.duration(to: .now).components
            return Double(value.seconds) + Double(value.attoseconds) / 1e18
        }
        let importStart = ContinuousClock.now
        let addStart = ContinuousClock.now
        session.add(urls)
        window.contentView?.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        let addAcknowledgement = elapsed(addStart)
        try await wait { session.preview != nil && !session.isRendering }
        let coldPreview = elapsed(importStart)
        try await wait { !session.isLoading }
        let importSeconds = elapsed(importStart)
        try check(session.batch.readyCount == count, "All workload files validated")

        var acknowledgements: [Double] = []
        var previews: [Double] = []
        let selectedIndices = [1, count - 1, 0, count / 2, 2, count - 2, 3, count / 2 + 1, 0, count - 3]
        for index in selectedIndices {
            let start = ContinuousClock.now
            session.select(session.batch.items[index].id)
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            acknowledgements.append(elapsed(start))
            try await wait { !session.isRendering && session.preview != nil }
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            previews.append(elapsed(start))
        }
        let exportStart = ContinuousClock.now
        session.startExport(to: output)
        try await wait { !session.isExporting }
        let exportSeconds = elapsed(exportStart)
        try check(session.summary?.saved == count && session.summary?.failed == 0, "All workload inputs saved")
        let perInput = session.summary!.processingSeconds

        var cancelAcknowledgements: [Double] = []
        var cancelCompletions: [Double] = []
        for _ in 0..<10 {
            session.startExport(to: output)
            let cancelStart = ContinuousClock.now
            session.cancelExport()
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            cancelAcknowledgements.append(elapsed(cancelStart))
            try await wait { !session.isExporting }
            cancelCompletions.append(elapsed(cancelStart))
            try check(session.summary?.cancelled == true, "Cancelled workload rerun")
        }
        var usage = rusage(); getrusage(RUSAGE_SELF, &usage)
        let report: [String: Any] = [
            "count": count, "os": ProcessInfo.processInfo.operatingSystemVersionString, "architecture": targetArchitecture,
            "backing_scale": window.backingScaleFactor, "window_points": NSStringFromSize(window.contentLayoutRect.size),
            "policy": "Keep original format", "flattened": true, "dpi": 450,
            "add_ack_seconds": addAcknowledgement, "cold_first_preview_seconds": coldPreview,
            "import_seconds": importSeconds, "selection_ack_seconds": acknowledgements,
            "selected_preview_seconds": previews, "selected_indices": selectedIndices,
            "export_seconds": exportSeconds, "per_input_seconds": perInput,
            "cancel_ack_seconds": cancelAcknowledgements, "cancel_completion_seconds": cancelCompletions,
            "max_rss_bytes": usage.ru_maxrss, "source_files": records,
            "method": "Separate release native-window process for each workload. UI acknowledgements include synchronous layout/displayIfNeeded. Preview completion polled at 10ms; ten selected-file changes include debounce, validation of reused bytes, rendering and display. First/cold preview retained separately. RSS is process high-water memory."
        ]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: output.appendingPathComponent("batch-measurement.json"))
        completed.append("Measured \(count)-file native-window workload")
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
