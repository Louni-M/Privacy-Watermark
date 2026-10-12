import Foundation
import WatermarkCore

/// Runs a resolved request through the app's own validation, naming and
/// publication. It adds only placement (beside each source or `--out`) and
/// terminal reporting; outcome counting stays in `BatchRunResult`.
struct Runner {
    var request: ExportRequest
    var currentDirectory: URL
    var standardOutput: @Sendable (String) -> Void
    var standardError: @Sendable (String) -> Void
    var boundary: @Sendable (UUID, ExportBoundary) throws -> Void

    static let stripPDFReason = "PDF metadata stripping is not supported. Only JPG and PNG images can be stripped."

    func run() async throws(CommandError) -> CommandStatus {
        let out = try outputDirectory()
        let (distinct, names) = distinctItems()
        var items = distinct
        var cancelled = false
        for index in items.indices {
            if Task.isCancelled { cancelled = true; break }
            if request.stripOnly && items[index].url.pathExtension.lowercased() == "pdf" {
                items[index].validation = .invalid(Self.stripPDFReason)
                continue
            }
            do { items[index].validation = .ready(try SourceValidation.inspect(items[index])) }
            catch is CancellationError { cancelled = true; break }
            catch { items[index].validation = .invalid(SourceValidation.message(for: error)) }
        }
        for item in items {
            if case .invalid(let reason) = item.validation { standardError("Excluded: \(names[item.id]!) — \(reason)") }
        }

        var result: BatchRunResult
        if cancelled {
            result = BatchRunResult()
            result.cancelled = true
            result.excluded = items.filter { if case .invalid = $0.validation { true } else { false } }.count
            result.unprocessed = items.count - result.excluded
        } else {
            let folders = Dictionary(uniqueKeysWithValues: items.map { item in
                (item.id, item.validation.metadata?.isPDF == true
                    && request.policy.resolve(for: item.url, settings: request.settings).format != .pdf)
            })
            let output = standardOutput, errors = standardError
            result = await BatchExport.run(items: items, watermark: request.watermark, policy: request.policy,
                settings: request.settings, suffix: request.suffix,
                destinationFor: { out ?? $0.url.deletingLastPathComponent() },
                boundary: boundary,
                update: { id, state, _ in
                    switch state {
                    case .saved(let urls):
                        guard let first = urls.first else { return }
                        output((folders[id] == true ? first.deletingLastPathComponent() : first).path)
                    case .failed(let reason): errors("Failed: \(names[id]!) — \(reason)")
                    default: break
                    }
                })
        }

        if result.cancelled { standardError("pwm: interrupted.") }
        standardError("\(result.saved) saved · \(result.failed) failed · \(result.excluded) excluded · \(result.unprocessed) not processed")
        if result.cancelled { return .interrupted }
        if result.saved == items.count { return .success }
        return result.saved > 0 ? .partial : .nothingSaved
    }

    /// `--out` must already exist and be writable; it is checked before any input is read.
    private func outputDirectory() throws(CommandError) -> URL? {
        guard let out = request.out else { return nil }
        let url = resolve(out)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue,
              access(url.path, W_OK | X_OK) == 0 else { throw .outputDirectory(out) }
        return url
    }

    /// Relative paths are taken from the command's current directory.
    private func resolve(_ path: String) -> URL {
        (path.hasPrefix("/") ? URL(fileURLWithPath: path) : currentDirectory.appendingPathComponent(path)).standardizedFileURL
    }

    /// The same file given twice, directly or through a link, is one input.
    /// Messages name each input as it was typed.
    private func distinctItems() -> ([BatchItem], [UUID: String]) {
        var seen = Set<FileIdentity>()
        var items: [BatchItem] = []
        var names: [UUID: String] = [:]
        for path in request.files {
            let item = BatchItem(url: resolve(path))
            guard seen.insert(item.identity).inserted else { continue }
            items.append(item)
            names[item.id] = path
        }
        return (items, names)
    }
}
