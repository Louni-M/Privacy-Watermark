import AppKit
import Observation
import UniformTypeIdentifiers
import WatermarkCore

actor ValidationWorker {
    func inspect(_ item: BatchItem) throws -> ValidatedSource { try SourceValidation.inspect(item) }
}

@MainActor @Observable
final class Session {
    private(set) var batch = BatchCollection()
    private(set) var preview: NSImage?
    private(set) var previewRegion = CGRect.zero
    private(set) var pageSize = CGSize.zero
    private(set) var pageIndex = 0
    private(set) var zoom: CGFloat?
    private(set) var viewReset = 0
    private(set) var viewportSize = CGSize(width: 700, height: 650)
    private(set) var backingScale: CGFloat = 1
    private(set) var viewportRegion: CGRect?
    private var sharedWatermark = WatermarkSettings()
    private var sharedExportSettings = ExportSettings()
    private var sharedOutputPolicy = OutputPolicy.original
    var watermark: WatermarkSettings {
        get { sharedWatermark }
        set {
            guard !isExporting, newValue != sharedWatermark else { return }
            sharedWatermark = newValue
            revision += 1; schedulePreview()
        }
    }
    var exportSettings: ExportSettings {
        get { sharedExportSettings }
        set {
            guard !isExporting, newValue != sharedExportSettings else { return }
            sharedExportSettings = newValue
            revision += 1; schedulePreview()
        }
    }
    var outputPolicy: OutputPolicy {
        get { sharedOutputPolicy }
        set {
            guard !isExporting, newValue != sharedOutputPolicy else { return }
            sharedOutputPolicy = newValue
            revision += 1; schedulePreview()
        }
    }
    private(set) var isRendering = false
    private(set) var isExporting = false
    private(set) var isCancelling = false
    private(set) var completedFiles = 0
    private(set) var totalFiles = 0
    private(set) var summary: BatchRunResult?
    private(set) var feedback = ""
    var errorMessage: String?
    @ObservationIgnored private let previewWorker = PreviewWorker()
    @ObservationIgnored private let validationWorker = ValidationWorker()
    @ObservationIgnored private var validationTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?
    @ObservationIgnored private var exportTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var validationGeneration = 0
    @ObservationIgnored private var revision = 0
    @ObservationIgnored private(set) var activePanel: NSSavePanel?
    @ObservationIgnored private(set) var displayedKey: PreviewKey?
    @ObservationIgnored var exportBoundary: @Sendable (UUID, ExportBoundary) throws -> Void = { _, _ in }

    var selected: BatchItem? { batch.selected }
    var isLoading: Bool { batch.checkingCount > 0 }
    var canExport: Bool { batch.readyCount > 0 && !isLoading && !isExporting }
    var isPDF: Bool { selected?.validation.metadata?.isPDF == true }
    var hasPDF: Bool { batch.items.contains { $0.url.pathExtension.lowercased() == "pdf" } }
    var pageCount: Int { selected?.validation.metadata?.pageCount ?? 0 }
    var effectiveScale: CGFloat {
        zoom ?? (pageSize.width > 0 && pageSize.height > 0
            ? min(viewportSize.width / pageSize.width, viewportSize.height / pageSize.height) : 1)
    }
    var fileInformation: String {
        guard let metadata = selected?.validation.metadata else { return "" }
        return metadata.isPDF ? "Page \(pageIndex + 1) of \(metadata.pageCount)"
            : "\(metadata.pixelWidth) × \(metadata.pixelHeight) pixels"
    }
    var status: String { summary?.message ?? "" }

    func chooseFiles() async {
        guard !isExporting, activePanel == nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "Add files"
        panel.message = "Add documents to watermark together. Your originals stay unchanged."
        if await present(panel) == .OK { add(panel.urls) }
    }

    func add(_ urls: [URL]) {
        guard !isExporting else { return }
        let before = batch.selectedID
        let previousCount = batch.items.count
        let local = urls.filter(\.isFileURL)
        let duplicates = batch.append(local)
        let added = batch.items.count - previousCount
        feedback = "\(added) added" + (duplicates > 0 ? " · \(duplicates) already added" : "")
            + (local.count < urls.count ? " · Only local files are supported" : "")
        summary = nil
        if before != batch.selectedID { selectionChanged() }
        beginValidation()
    }

    func select(_ id: UUID) {
        guard id != batch.selectedID else { return }
        batch.select(id)
        selectionChanged()
    }

    func remove(_ id: UUID) {
        guard !isExporting else { return }
        let before = batch.selectedID
        batch.remove(id)
        summary = nil
        if before != batch.selectedID { selectionChanged() }
    }

    func clearAll() {
        guard !isExporting else { return }
        validationGeneration += 1
        validationTask?.cancel()
        validationTask = nil
        batch.clear()
        feedback = ""
        summary = nil
        selectionChanged()
    }

    private func beginValidation() {
        guard validationTask == nil, let item = batch.items.first(where: { $0.validation == .checking }) else { return }
        let ticket = validationGeneration
        let worker = validationWorker
        validationTask = Task { [weak self] in
            let work = Task.detached(priority: .utility) { try await worker.inspect(item) }
            let result = await withTaskCancellationHandler { await work.result } onCancel: { work.cancel() }
            guard let self, !Task.isCancelled, ticket == validationGeneration else { return }
            validationTask = nil
            if batch.items.contains(where: { $0.id == item.id }) {
                switch result {
                case .success(let metadata): batch.update(item.id) { $0.validation = .ready(metadata) }
                case .failure(let error): batch.update(item.id) { $0.validation = .invalid(SourceValidation.message(for: error)) }
                }
                if batch.selectedID == item.id { schedulePreview() }
            }
            beginValidation()
        }
    }

    private func selectionChanged() {
        pageIndex = 0
        zoom = nil
        pageSize = .zero
        viewportRegion = nil
        preview = nil
        displayedKey = nil
        viewReset += 1
        schedulePreview()
    }

    func changePage(_ delta: Int) {
        let next = pageIndex + delta
        guard isPDF, (0..<pageCount).contains(next) else { return }
        pageIndex = next
        pageSize = .zero
        viewportRegion = nil
        preview = nil
        displayedKey = nil
        viewReset += 1
        schedulePreview()
    }

    func setZoom(_ value: CGFloat?) {
        zoom = value.map { min(4, max(0.25, $0)) }
        viewportRegion = nil
        preview = nil
        displayedKey = nil
        viewReset += 1
        schedulePreview()
    }

    func updateViewport(size: CGSize, region: CGRect?, backingScale: CGFloat) {
        guard size.width > 0, size.height > 0 else { return }
        let nextRegion = zoom == nil ? nil : region
        guard size != viewportSize || nextRegion != viewportRegion || backingScale != self.backingScale else { return }
        viewportSize = size
        viewportRegion = nextRegion
        self.backingScale = backingScale
        schedulePreview()
    }

    func schedulePreview() {
        previewTask?.cancel()
        generation += 1
        let ticket = generation
        guard let item = selected, let metadata = item.validation.metadata else {
            preview = nil
            displayedKey = nil
            isRendering = false
            let worker = previewWorker
            Task { await worker.clear() }
            return
        }
        let page = pageIndex
        let watermark = watermark
        let output = outputPolicy.resolve(for: item.url, settings: exportSettings)
        let revision = revision
        isRendering = true
        previewTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(80))
                let size = try await previewWorker.size(item, page: page)
                guard !Task.isCancelled, ticket == generation else { return }
                pageSize = size
                let scale = effectiveScale
                let initial = CGRect(x: 0, y: max(0, size.height - viewportSize.height / scale),
                    width: min(size.width, viewportSize.width / scale), height: min(size.height, viewportSize.height / scale))
                let region = zoom == nil ? CGRect(origin: .zero, size: size) : (viewportRegion ?? initial)
                let key = PreviewKey(itemID: item.id, fingerprint: metadata.fingerprint, page: page, revision: revision,
                    watermark: watermark, output: output,
                    viewport: PreviewViewport(region: region, scale: scale, backingScale: backingScale, detailed: zoom != nil))
                let bytes = try await previewWorker.render(item, key: key)
                guard !Task.isCancelled, ticket == generation, selected?.id == item.id else { return }
                guard let image = NSImage(data: bytes) else { throw DocumentError.renderFailed }
                preview = image
                previewRegion = region
                displayedKey = key
                isRendering = false
            } catch {
                guard !Task.isCancelled, ticket == generation else { return }
                preview = nil
                displayedKey = nil
                isRendering = false
                let message = SourceValidation.message(for: error)
                if let error = error as? DocumentError, [.sourceChanged, .sourceUnavailable].contains(error) {
                    batch.update(item.id) { $0.validation = .invalid(message) }
                } else { errorMessage = message }
            }
        }
    }

    func chooseDestination() async {
        guard canExport, activePanel == nil else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = selected?.url.deletingLastPathComponent()
        panel.prompt = "Export here"
        panel.message = "Save watermarked copies in this folder. Existing files stay unchanged."
        guard await present(panel) == .OK, let url = panel.url else { return }
        startExport(to: url)
    }

    private func present(_ panel: NSSavePanel) async -> NSApplication.ModalResponse {
        activePanel = panel
        defer { activePanel = nil }
        return await withCheckedContinuation { continuation in
            let completion: (NSApplication.ModalResponse) -> Void = { continuation.resume(returning: $0) }
            if let window = NSApplication.shared.mainWindow { panel.beginSheetModal(for: window, completionHandler: completion) }
            else { panel.begin(completionHandler: completion) }
        }
    }

    func startExport(to destination: URL) {
        guard canExport else { return }
        let items = batch.items
        let watermark = watermark
        let policy = outputPolicy
        let settings = exportSettings
        let boundary = exportBoundary
        isExporting = true
        isCancelling = false
        completedFiles = 0
        totalFiles = batch.readyCount
        summary = nil
        errorMessage = nil
        for item in items where item.validation.metadata != nil { batch.update(item.id) { $0.export = .pending } }
        exportTask = Task {
            let session = self
            let work = Task.detached(priority: .utility) {
                await BatchExport.run(items: items, watermark: watermark, policy: policy, settings: settings, destination: destination,
                    boundary: boundary) { id, state, count in
                    await session.recordExport(id, state: state, count: count)
                }
            }
            let result = await withTaskCancellationHandler { await work.value } onCancel: { work.cancel() }
            summary = result
            isExporting = false
            isCancelling = false
            exportTask = nil
        }
    }

    private func recordExport(_ id: UUID, state: ExportState, count: Int) {
        batch.update(id) {
            $0.export = state
            if case .failed(let message) = state,
               [DocumentError.sourceChanged.localizedDescription, DocumentError.sourceUnavailable.localizedDescription].contains(message) {
                $0.validation = .invalid(message)
            }
        }
        if id == batch.selectedID, batch.selected?.validation.metadata == nil {
            schedulePreview()
        }
        completedFiles = count
    }

    func cancelExport() {
        guard isExporting else { return }
        isCancelling = true
        exportTask?.cancel()
    }
}
