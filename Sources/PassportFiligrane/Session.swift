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
    var preview: NSImage? { (details[pageIndex] ?? overviews[pageIndex])?.image }
    var previewRegion: CGRect { (details[pageIndex] ?? overviews[pageIndex])?.key.viewport.region ?? .zero }
    var displayedKey: PreviewKey? { (details[pageIndex] ?? overviews[pageIndex])?.key }
    private(set) var pageSize = CGSize.zero
    private(set) var pageSizes: [CGSize] = []
    private(set) var fitReference = 0
    private(set) var visibleRegions: [Int: CGRect] = [:]
    private(set) var scrollOrigin = CGPoint.zero
    private(set) var navigationRevision = 0
    private(set) var navigationTarget = 0
    private(set) var zoomRequest: CGFloat?
    private(set) var zoomRequestRevision = 0
    struct PageImage {
        let image: NSImage
        let key: PreviewKey
        let cost: Int
    }
    private(set) var overviews: [Int: PageImage] = [:]
    private(set) var details: [Int: PageImage] = [:]
    static let maximumDisplayedBytes = 48 * 1024 * 1024
    var displayedBytes: Int { (Array(overviews.values) + Array(details.values)).reduce(0) { $0 + $1.cost } }
    private(set) var pageIndex = 0
    private(set) var transitionScale: CGFloat?
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
    @ObservationIgnored var previewBoundary: @Sendable (PreviewKey) throws -> Void = { _ in }
    @ObservationIgnored var exportBoundary: @Sendable (UUID, ExportBoundary) throws -> Void = { _, _ in }

    var selected: BatchItem? { batch.selected }
    var isLoading: Bool { batch.checkingCount > 0 }
    var canExport: Bool { batch.readyCount > 0 && !isLoading && !isExporting }
    var isPDF: Bool { selected?.validation.metadata?.isPDF == true }
    var hasPDF: Bool { batch.items.contains { $0.url.pathExtension.lowercased() == "pdf" } }
    var pageCount: Int { selected?.validation.metadata?.pageCount ?? 0 }
    var fitScale: CGFloat {
        let size = pageSizes.indices.contains(fitReference) ? pageSizes[fitReference] : pageSize
        return size.width > 0 && size.height > 0
            ? min(viewportSize.width / size.width, viewportSize.height / size.height) : 1
    }
    var minimumZoom: CGFloat { min(0.01, fitScale) }
    var effectiveScale: CGFloat { transitionScale ?? zoom ?? fitScale }
    func boundedZoom(_ value: CGFloat) -> CGFloat {
        // Admit fit scales beyond 400% and move continuously toward the normal range.
        min(max(4, fitScale), max(minimumZoom, value))
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
        fitReference = 0
        pageSizes = []
        visibleRegions = [:]
        scrollOrigin = .zero
        overviews = [:]; details = [:]
        zoom = nil
        transitionScale = nil
        pageSize = .zero
        viewportRegion = nil
        viewReset += 1
        schedulePreview()
    }

    func changePage(_ delta: Int) {
        let next = pageIndex + delta
        guard isPDF, (0..<pageCount).contains(next) else { return }
        pageIndex = next
        if zoom == nil { fitReference = next }
        if pageSizes.indices.contains(next) { pageSize = pageSizes[next] }
        navigationTarget = next
        navigationRevision += 1
        visibleRegions = [:]
        viewportRegion = nil
        schedulePreview()
    }

    func requestZoom(_ value: CGFloat?) {
        zoomRequest = value
        zoomRequestRevision += 1
    }

    func setTransitionScale(_ value: CGFloat?) {
        transitionScale = value
        schedulePreview()
    }

    func setZoom(_ value: CGFloat?) {
        transitionScale = nil
        if value == nil { fitReference = pageIndex }
        zoom = value.map { boundedZoom($0) }
        viewportRegion = nil
        if value == nil {
            navigationTarget = pageIndex
            navigationRevision += 1
            viewReset += 1
        }
        schedulePreview()
    }

    func updateViewport(size: CGSize, region: CGRect?, backingScale: CGFloat) {
        updateViewport(size: size, regions: region.map { [pageIndex: $0] } ?? [:],
            origin: scrollOrigin, currentPage: pageIndex, backingScale: backingScale)
    }

    func updateViewport(size: CGSize, regions: [Int: CGRect], origin: CGPoint,
                        currentPage: Int, backingScale: CGFloat) {
        guard size.width > 0, size.height > 0 else { return }
        let changed = size != viewportSize || regions != visibleRegions || backingScale != self.backingScale
        if size != viewportSize { transitionScale = nil }
        viewportSize = size
        visibleRegions = regions
        viewportRegion = regions[currentPage]
        scrollOrigin = origin
        if pageSizes.indices.contains(currentPage) {
            pageIndex = currentPage
            pageSize = pageSizes[currentPage]
        }
        self.backingScale = backingScale
        if changed { schedulePreview() }
    }

    private func retain(_ bytes: Data, key: PreviewKey, overview: Bool) throws {
        guard let representation = NSBitmapImageRep(data: bytes), let cgImage = representation.cgImage else {
            throw DocumentError.renderFailed
        }
        let cost = bytes.count + cgImage.bytesPerRow * cgImage.height
        guard cost <= Self.maximumDisplayedBytes else { throw DocumentError.renderFailed }
        let image = NSImage(cgImage: cgImage, size: key.viewport.region.size)
        let entry = PageImage(image: image, key: key, cost: cost)
        if overview { overviews[key.page] = entry } else { details[key.page] = entry }
        // Offscreen detail is the first eviction candidate, then distant overviews.
        for page in details.keys.sorted(by: { abs($0 - pageIndex) > abs($1 - pageIndex) }) where displayedBytes > Self.maximumDisplayedBytes {
            if page != key.page { details[page] = nil }
        }
        for page in overviews.keys.sorted(by: { abs($0 - pageIndex) > abs($1 - pageIndex) }) where displayedBytes > Self.maximumDisplayedBytes {
            overviews[page] = nil
        }
        if displayedBytes > Self.maximumDisplayedBytes { details[key.page] = nil }
    }

    func retainedPreviewBytes() async -> Int {
        displayedBytes + (await previewWorker.cacheBytes)
    }

    func schedulePreview() {
        previewTask?.cancel()
        generation += 1
        let ticket = generation
        guard let item = selected, let metadata = item.validation.metadata else {
            overviews = [:]; details = [:]
            isRendering = false
            let worker = previewWorker
            Task { await worker.clear() }
            return
        }
        let watermark = watermark
        let output = outputPolicy.resolve(for: item.url, settings: exportSettings)
        let revision = revision
        // Never display imagery from obsolete settings, policies or files.
        overviews = overviews.filter { $0.value.key.revision == revision && $0.value.key.itemID == item.id }
        details = details.filter { $0.value.key.revision == revision && $0.value.key.itemID == item.id }
        isRendering = true
        previewTask = Task { [weak self] in
            guard let self else { return }
            do {
                if pageSizes.isEmpty {
                    let sizes = try await previewWorker.sizes(item)
                    guard !Task.isCancelled, ticket == generation else { return }
                    pageSizes = sizes
                    pageSize = sizes[pageIndex]
                }
                let scale = effectiveScale
                let sizes = pageSizes
                var regions = visibleRegions
                if regions.isEmpty {
                    let size = sizes[pageIndex]
                    regions[pageIndex] = CGRect(x: 0, y: max(0, size.height - viewportSize.height / scale),
                        width: min(size.width, viewportSize.width / scale), height: min(size.height, viewportSize.height / scale))
                }
                details = details.filter { regions[$0.key] != nil }
                overviews = overviews.filter { abs($0.key - pageIndex) <= 1 || regions[$0.key] != nil }
                let visible = regions.keys.sorted { abs($0 - pageIndex) < abs($1 - pageIndex) }
                let neighbors = Set(visible.flatMap { [$0 - 1, $0 + 1] }).filter {
                    sizes.indices.contains($0) && regions[$0] == nil
                }.sorted()
                func key(_ page: Int, _ region: CGRect, _ requestedScale: CGFloat, _ detailed: Bool) -> PreviewKey {
                    // Reserve half the shared retained budget for display; even
                    // unusually large windows cannot request an oversized image.
                    let safeScale = min(requestedScale, sqrt(8_000_000 / CGFloat(max(1, visible.count)) / max(1, region.width * region.height)) * 0.99)
                    return PreviewKey(itemID: item.id, fingerprint: metadata.fingerprint, page: page, revision: revision,
                        watermark: watermark, output: output,
                        viewport: PreviewViewport(region: region, scale: safeScale, backingScale: 1, detailed: detailed))
                }
                // Provisional visible page images arrive before debounced detail.
                for page in visible where overviews[page] == nil {
                    let size = sizes[page]
                    let request = key(page, CGRect(origin: .zero, size: size), min(scale * backingScale, 1, 512 / max(size.width, size.height)), false)
                    try previewBoundary(request)
                    let bytes = try await previewWorker.render(item, key: request)
                    guard !Task.isCancelled, ticket == generation, selected?.id == item.id else { return }
                    try retain(bytes, key: request, overview: true)
                }
                try await Task.sleep(for: .milliseconds(80))
                for page in visible {
                    let request = key(page, regions[page]!, scale * backingScale, true)
                    try previewBoundary(request)
                    let bytes = try await previewWorker.render(item, key: request)
                    guard !Task.isCancelled, ticket == generation, selected?.id == item.id else { return }
                    try retain(bytes, key: request, overview: false)
                }
                isRendering = false
                for page in neighbors where overviews[page] == nil && displayedBytes < Self.maximumDisplayedBytes - 2 * 1024 * 1024 {
                    let size = sizes[page]
                    let request = key(page, CGRect(origin: .zero, size: size), min(scale * backingScale, 1, 512 / max(size.width, size.height)), false)
                    try previewBoundary(request)
                    let bytes = try await previewWorker.render(item, key: request)
                    guard !Task.isCancelled, ticket == generation, selected?.id == item.id else { return }
                    try retain(bytes, key: request, overview: true)
                }
            } catch {
                guard !Task.isCancelled, ticket == generation else { return }
                isRendering = false
                let message = SourceValidation.message(for: error)
                if let error = error as? DocumentError, [.sourceChanged, .sourceUnavailable].contains(error) {
                    overviews = [:]; details = [:]
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
