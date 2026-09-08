import AppKit
import SwiftUI
import PDFKit
import ImageIO
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
        window.title = "Passport Filigrane — Native smoke test"
        let hostingView = NSHostingView(rootView: ContentView(session: session))
        // Honor the requested test window size instead of resizing to SwiftUI's
        // preferred content height whenever selection changes.
        hostingView.sizingOptions = [.minSize]
        window.contentView = hostingView
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
        if ProcessInfo.processInfo.environment["PASSPORT_PREVIEW_ACCEPTANCE"] != nil { try await previewAcceptance(); return }
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

    func previewAcceptance() async throws {
        // Give external window managers a moment to register this test window.
        try await Task.sleep(for: .seconds(1))
        let imageURL = output.appendingPathComponent("Synthetic 高解像度 document with a deliberately long filename for checking two lines and truncation at the minimum supported window size.jpg")
        let width = 4200, height = 5940
        guard let bitmap = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw DocumentError.renderFailed
        }
        bitmap.setFillColor(CGColor(gray: 0.85, alpha: 1)); bitmap.fill(CGRect(x: 0, y: 0, width: width, height: height))
        bitmap.setFillColor(CGColor(gray: 0.3, alpha: 1))
        for row in 0..<12 { bitmap.fill(CGRect(x: 400, y: 400 + row * 400, width: 2800, height: 35)) }
        guard let cgImage = bitmap.makeImage(), let destination = CGImageDestinationCreateWithURL(imageURL as CFURL, "public.jpeg" as CFString, 1, nil) else { throw DocumentError.writeFailed }
        CGImageDestinationAddImage(destination, cgImage, nil)
        try check(CGImageDestinationFinalize(destination), "Synthetic photo created")
        let pdfURL = output.appendingPathComponent("synthetic-mixed-50.pdf")
        var box = CGRect(x: 0, y: 0, width: 595.275590551, height: 841.88976378)
        guard let pdf = CGContext(pdfURL as CFURL, mediaBox: &box, nil) else { throw DocumentError.writeFailed }
        for index in 0..<50 {
            box = CGRect(x: 0, y: 0, width: index % 3 == 0 ? 595.275590551 : 400,
                height: index % 3 == 0 ? 841.88976378 : 600)
            let data = Data(bytes: &box, count: MemoryLayout<CGRect>.size)
            pdf.beginPDFPage([kCGPDFContextMediaBox as String: data] as CFDictionary)
            pdf.setFillColor(CGColor(gray: 0.85, alpha: 1)); pdf.fill(box)
            pdf.setFillColor(CGColor(gray: 0.3, alpha: 1))
            for row in 0..<12 { pdf.fill(CGRect(x: box.width * 400 / 4200, y: box.height * CGFloat(400 + row * 400) / 5940,
                width: box.width * 2800 / 4200, height: box.height * 35 / 5940)) }
            pdf.endPDFPage()
        }
        pdf.closePDF()
        if let document = PDFDocument(url: pdfURL) {
            for index in 1..<50 where index % 2 == 1 {
                document.page(at: index)?.rotation = 90
                document.page(at: index)?.setBounds(CGRect(x: 20, y: 30, width: 360, height: 540), for: .cropBox)
            }
            try check(document.write(to: pdfURL), "Rotated/cropped fixture created")
        }
        window.setContentSize(CGSize(width: 860, height: 600))
        session.add([imageURL, pdfURL])
        session.watermark.color = .black
        try await wait { !session.isLoading && !session.isRendering }
        try check(session.effectiveScale < 0.25, "High resolution photo fits below 25 percent")
        window.setFrame(NSRect(x: 100, y: 100, width: 860, height: 622), display: true)
        try await Task.sleep(for: .milliseconds(250))
        try await wait { !session.isRendering }
        try check(abs((window.contentView?.bounds.height ?? 0) - 600) < 1, "Actual minimum window height: bounds=\(String(describing: window.contentView?.bounds)) min=\(window.contentMinSize) layout=\(window.contentLayoutRect)")
        try capture("photo-fit")
        let originalFit = session.effectiveScale
        session.requestZoom(originalFit * 1.2)
        try await Task.sleep(for: .milliseconds(70))
        try check(session.effectiveScale > originalFit && session.effectiveScale < originalFit * 1.2, "Zoom has intermediate scale")
        try await Task.sleep(for: .milliseconds(200))
        try await wait { !session.isRendering }
        try check(abs(session.effectiveScale - originalFit * 1.2) < 0.0001, "Zoom button takes a continuous 1.2 step")
        try capture("photo-zoom")
        session.requestZoom(nil)
        try await Task.sleep(for: .milliseconds(300))
        try await wait { !session.isRendering }
        try check(session.zoom == nil, "Animated Fit returns to fit mode")
        session.select(session.batch.items[1].id)
        try await wait { !session.isRendering }
        try capture("pdf-fit")
        var peak = await session.retainedPreviewBytes()
        var longestAcknowledgement = 0.0
        for page in 1..<50 {
            let start = ContinuousClock.now
            session.changePage(1)
            if page % 8 == 0 { session.watermark.text = "COPY \(page)" }
            window.contentView?.layoutSubtreeIfNeeded()
            let duration = start.duration(to: .now).components
            longestAcknowledgement = max(longestAcknowledgement, Double(duration.seconds) + Double(duration.attoseconds) / 1e18)
            if page % 10 == 0 {
                try await Task.sleep(for: .milliseconds(220))
                peak = max(peak, await session.retainedPreviewBytes())
            }
        }
        try await Task.sleep(for: .milliseconds(300))
        try await wait { !session.isRendering }
        peak = max(peak, await session.retainedPreviewBytes())
        try check(peak <= 96 * 1024 * 1024, "Retained preview budget")
        try capture("pdf-stress-settled")
        for index in 0..<12 {
            session.select(session.batch.items[index % 2].id)
            session.watermark.text = "SWITCH \(index)"
            session.setZoom(index % 2 == 0 ? 0.15 : 1.2)
            try await Task.sleep(for: .milliseconds(15))
        }
        try await wait { !session.isRendering }
        try check(session.displayedKey?.itemID == session.selected?.id && session.displayedKey?.watermark.text == "SWITCH 11", "Pending high-resolution file/settings replacements stay current")
        // Inject a render failure without changing the source or export snapshot.
        session.previewBoundary = { _ in throw DocumentError.renderFailed }
        session.schedulePreview()
        try await wait { !session.isRendering }
        try check(session.errorMessage != nil, "Preview render failure reports a recoverable error")
        session.errorMessage = nil
        session.previewBoundary = { _ in }
        session.setZoom(nil)
        try await wait { !session.isRendering }
        try check(session.preview != nil && session.canExport, "Preview failure recovers")
        // Reopen real exports as new selected files in the same native viewer.
        session.watermark.text = "COPY"
        session.exportSettings.flattened = false
        session.startExport(to: output)
        try await wait { !session.isExporting }
        try check(session.summary?.saved == 2, "Stress leaves export correctness intact")
        let outputs = session.batch.items.flatMap { item -> [URL] in
            if case .saved(let urls) = item.export { return urls }; return []
        }
        session.clearAll()
        session.watermark.text = ""
        session.add(outputs)
        try await wait { !session.isLoading && !session.isRendering }
        try capture("photo-reopened")
        session.select(session.batch.items[1].id)
        try await wait { !session.isRendering }
        try capture("pdf-reopened")
        let report: [String: Any] = ["peak_retained_preview_bytes": peak,
            "retained_budget_bytes": 96 * 1024 * 1024, "maximum_render_pixels": PreviewRendering.maximumPixels,
            "largest_navigation_ack_seconds": longestAcknowledgement,
            "photo_pixels": [width, height], "pdf_pages": 50,
            "real_trackpad_pinch_momentum_mouse_wheel_command_wheel": "pending: physical input not exercised",
            "note": "Programmatic native-window checks; source document storage and transient render scratch are outside retained preview cache accounting."]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: output.appendingPathComponent("preview-acceptance.json"))
        completed.append("Synthetic high-resolution photo, animated zoom/Fit, 50-page mixed PDF stress, retained budget, exports and native reopen screenshots")
    }

    func capture(_ name: String) throws {
        guard let view = window.contentView else { throw DocumentError.renderFailed }
        view.layoutSubtreeIfNeeded(); view.displayIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw DocumentError.renderFailed }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { throw DocumentError.renderFailed }
        try data.write(to: output.appendingPathComponent(name + ".png"))
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
