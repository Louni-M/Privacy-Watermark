import Foundation
import Darwin

public struct DestinationAllocator {
    let directory: URL
    let protectedSources: [URL]
    private var reserved: Set<String> = []
    private let caseSensitive: Bool

    public init(directory: URL, sources: [URL]) {
        self.directory = directory
        protectedSources = sources
        caseSensitive = (try? directory.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey]))?
            .volumeSupportsCaseSensitiveNames ?? false
    }

    private func key(_ name: String) -> String {
        let normalized = name.precomposedStringWithCanonicalMapping
        return caseSensitive ? normalized : normalized.lowercased()
    }

    public mutating func allocate(source: URL, format: OutputFormat, pageSeries: Bool) -> URL {
        let stem = source.deletingPathExtension().lastPathComponent + "_watermarked"
        var suffix = 1
        while true {
            let name = stem + (suffix == 1 ? "" : " (\(suffix))") + (pageSeries ? "" : ".\(format.fileExtension)")
            let candidate = directory.appendingPathComponent(name, isDirectory: pageSeries)
            var info = stat()
            let exists = candidate.withUnsafeFileSystemRepresentation { path in path.map { lstat($0, &info) == 0 } ?? true }
            let canonical = candidate.resolvingSymlinksInPath().standardizedFileURL
            let protected = protectedSources.contains { source in
                let other = source.resolvingSymlinksInPath().standardizedFileURL
                return other == canonical || (other.deletingLastPathComponent() == canonical.deletingLastPathComponent()
                    && key(other.lastPathComponent) == key(name))
            }
            if !exists && !protected && reserved.insert(key(name)).inserted { return candidate }
            suffix += 1
        }
    }
}

public enum ExportBoundary: Sendable {
    case beforeInput, beforePage(Int), beforePublication, afterPublication
}

public struct BatchRunResult: Equatable, Sendable {
    public var saved = 0
    public var failed = 0
    public var unprocessed = 0
    public var cancelled = false
    public var processingSeconds: [Double] = []
    public init() {}
    public var message: String {
        "\(saved) saved · \(failed) failed · \(unprocessed) not processed" + (cancelled ? " · Cancelled" : "")
    }
}

public enum BatchExport {
    /// A whole source (including its page folder) has one exclusive rename as
    /// its completion boundary. No user destination enters a replacement path.
    public static func save(_ source: SourceDocument, watermark: WatermarkSettings, settings: ExportSettings,
                            allocator: inout DestinationAllocator,
                            boundary: (ExportBoundary) throws -> Void = { _ in }) throws -> [URL] {
        try Task.checkCancellation()
        let files = FileManager.default
        let directory = allocator.directory.appendingPathComponent(".passport-batch-\(UUID().uuidString)", isDirectory: true)
        try files.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? files.removeItem(at: directory) }
        let series = source.kind == .pdf && settings.format != .pdf
        let staged = directory.appendingPathComponent(series ? "pages" : "output.\(settings.format.fileExtension)", isDirectory: series)
        if series { try files.createDirectory(at: staged, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
        let prepared = try Processing.export(source, watermark: watermark, settings: settings, destination: staged,
            pageBoundary: { try boundary(.beforePage($0)) })
        var destination = allocator.allocate(source: source.url, format: settings.format, pageSeries: series)
        try boundary(.beforePublication)
        while true {
            try Task.checkCancellation()
            let code = staged.withUnsafeFileSystemRepresentation { from in
                destination.withUnsafeFileSystemRepresentation { to in
                    renamex_np(from!, to!, UInt32(RENAME_EXCL))
                }
            }
            if code == 0 { break }
            guard errno == EEXIST || errno == ENOTEMPTY else { throw DocumentError.writeFailed }
            destination = allocator.allocate(source: source.url, format: settings.format, pageSeries: series)
        }
        // Cancellation after publication must never turn a saved item into a
        // failure. The next input observes cancellation before loading bytes.
        try? boundary(.afterPublication)
        return series ? prepared.map { destination.appendingPathComponent($0.lastPathComponent) } : [destination]
    }

    public static func run(items: [BatchItem], watermark: WatermarkSettings, policy: OutputPolicy, settings: ExportSettings,
                           destination: URL,
                           boundary: @Sendable (UUID, ExportBoundary) throws -> Void = { _, _ in },
                           update: @Sendable (UUID, ExportState, Int) async -> Void) async -> BatchRunResult {
        var result = BatchRunResult()
        result.failed = items.filter { $0.validation.metadata == nil }.count
        let eligible = items.filter { $0.validation.metadata != nil }
        var allocator = DestinationAllocator(directory: destination, sources: items.map(\.url))
        var completed = 0
        for (index, item) in eligible.enumerated() {
            if Task.isCancelled {
                result.cancelled = true
                result.unprocessed = eligible.count - index
                for remaining in eligible[index...] { await update(remaining.id, .unprocessed, completed) }
                break
            }
            await update(item.id, .exporting, completed)
            let started = ContinuousClock.now
            do {
                try boundary(item.id, .beforeInput)
                try Task.checkCancellation()
                let outputs = try autoreleasepool {
                    let source = try SourceValidation.load(item.url, identity: item.identity, validated: item.validation.metadata)
                    return try save(source, watermark: watermark, settings: policy.resolve(for: item.url, settings: settings),
                        allocator: &allocator, boundary: { try boundary(item.id, $0) })
                }
                result.saved += 1
                let elapsed = started.duration(to: .now).components
                result.processingSeconds.append(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18)
                completed += 1
                await update(item.id, .saved(outputs), completed)
            } catch is CancellationError {
                result.cancelled = true
                result.unprocessed = eligible.count - index
                for remaining in eligible[index...] { await update(remaining.id, .unprocessed, completed) }
                break
            } catch {
                result.failed += 1
                let elapsed = started.duration(to: .now).components
                result.processingSeconds.append(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18)
                completed += 1
                await update(item.id, .failed(SourceValidation.message(for: error)), completed)
            }
        }
        return result
    }
}
