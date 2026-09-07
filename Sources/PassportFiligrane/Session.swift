import AppKit
import Observation
import UniformTypeIdentifiers
import WatermarkCore

actor DocumentWorker {
    func load(_ url: URL) throws -> SourceDocument { try SourceDocument.load(url) }
    func preview(_ source: SourceDocument, watermark: WatermarkSettings, export: ExportSettings) throws -> Data {
        try Task.checkCancellation()
        return try Processing.preview(source, watermark: watermark, export: export)
    }
    func export(_ source: SourceDocument, watermark: WatermarkSettings, settings: ExportSettings, destination: URL, replace: Bool) throws -> [URL] {
        try Processing.export(source, watermark: watermark, settings: settings, destination: destination, replaceExisting: replace)
    }
}

@MainActor @Observable
final class Session {
    private(set) var document: SourceDocument?
    private(set) var preview: NSImage?
    var watermark = WatermarkSettings() { didSet { if oldValue != watermark { schedulePreview() } } }
    var exportSettings = ExportSettings() { didSet { if oldValue != exportSettings { schedulePreview() } } }
    private(set) var isLoading = false
    private(set) var isRendering = false
    private(set) var isExporting = false
    var errorMessage: String?
    private(set) var status = ""
    @ObservationIgnored private let worker = DocumentWorker()
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var loadGeneration = 0
    @ObservationIgnored private(set) var activePanel: NSSavePanel?

    var canExport: Bool { document != nil && !isLoading && !isExporting }
    var isPDF: Bool { document?.kind == .pdf }
    var exportAsImages: Bool { isPDF && exportSettings.format != .pdf }
    var fileInformation: String {
        guard let document else { return "" }
        return isPDF ? "\(document.pageCount) \(document.pageCount == 1 ? "page" : "pages") · Preview of page 1" : "\(document.pixelWidth) × \(document.pixelHeight) pixels"
    }

    func chooseFile() async {
        guard !isExporting, activePanel == nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a document to watermark. Your original stays unchanged."
        if await present(panel) == .OK, let url = panel.url { load(url) }
    }

    func load(_ url: URL) {
        guard !isExporting else { return }
        generation += 1
        loadGeneration += 1
        let request = loadGeneration
        loadTask?.cancel()
        previewTask?.cancel()
        isRendering = false
        isLoading = true
        errorMessage = nil
        status = ""
        loadTask = Task {
            do {
                let source = try await worker.load(url)
                guard !Task.isCancelled, request == loadGeneration else { return }
                document = source
                preview = nil
                isLoading = false
                exportSettings.format = source.kind == .image ? .jpg : .pdf
                schedulePreview()
            } catch {
                guard !Task.isCancelled, request == loadGeneration else { return }
                isLoading = false
                report(error)
                if document != nil { schedulePreview() }
            }
        }
    }

    func schedulePreview() {
        previewTask?.cancel()
        generation += 1
        let request = generation
        guard let document, !isLoading else { return }
        let settings = watermark
        let output = exportSettings
        isRendering = true
        status = ""
        previewTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(120))
                let bytes = try await worker.preview(document, watermark: settings, export: output)
                guard !Task.isCancelled, request == generation else { return }
                guard let image = NSImage(data: bytes) else { throw DocumentError.renderFailed }
                preview = image
                isRendering = false
            } catch {
                guard !Task.isCancelled, request == generation else { return }
                isRendering = false
                report(error)
            }
        }
    }

    func chooseDestination() async {
        guard canExport, activePanel == nil, let document else { return }
        let destination: URL
        if exportAsImages {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.directoryURL = document.url.deletingLastPathComponent()
            panel.prompt = "Export here"
            panel.message = "Save one \(exportSettings.format.rawValue) image for each PDF page."
            guard await present(panel) == .OK, let url = panel.url else { return }
            destination = url
        } else {
            let panel = NSSavePanel()
            panel.directoryURL = document.url.deletingLastPathComponent()
            panel.allowedContentTypes = [exportSettings.format == .pdf ? .pdf : exportSettings.format == .png ? .png : .jpeg]
            panel.nameFieldStringValue = "export_filigree.\(exportSettings.format.fileExtension)"
            panel.canCreateDirectories = true
            guard await present(panel) == .OK, let url = panel.url else { return }
            destination = url
        }
        let outputs = Processing.destinations(for: document, export: exportSettings, destination: destination)
        let existing = outputs.filter { FileManager.default.fileExists(atPath: $0.path) }
        if exportAsImages && !existing.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Replace \(existing.count) existing \(existing.count == 1 ? "file" : "files")?"
            alert.informativeText = "Files with matching page names in this folder will be replaced."
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        startExport(to: destination, replace: !existing.isEmpty)
    }

    private func present(_ panel: NSSavePanel) async -> NSApplication.ModalResponse {
        activePanel = panel
        defer { activePanel = nil }
        return await withCheckedContinuation { continuation in
            let completion: (NSApplication.ModalResponse) -> Void = { response in continuation.resume(returning: response) }
            if let window = NSApplication.shared.mainWindow {
                panel.beginSheetModal(for: window, completionHandler: completion)
            } else {
                panel.begin(completionHandler: completion)
            }
        }
    }

    func startExport(to destination: URL, replace: Bool = false) {
        guard canExport, let document else { return }
        let watermark = watermark
        let settings = exportSettings
        isExporting = true
        errorMessage = nil
        status = ""
        Task {
            do {
                let outputs = try await worker.export(document, watermark: watermark, settings: settings, destination: destination, replace: replace)
                status = outputs.count == 1 ? "Saved \(outputs[0].lastPathComponent)" : "Exported \(outputs.count) page images"
            } catch { report(error) }
            isExporting = false
        }
    }

    private func report(_ error: Error) {
        // Present known safe descriptions, never arbitrary decoder messages containing
        // document contents, watermark text, or private paths. No file log is needed.
        if let error = error as? DocumentError { errorMessage = error.localizedDescription }
        else { errorMessage = "Unable to complete this operation. Check the file, destination, and available disk space, then try again." }
    }
}
