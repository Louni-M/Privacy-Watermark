import Foundation

/// Metadata-only prediction. Actual writes and collision allocation stay with BatchExporter.
public struct ExportPrediction: Equatable, Sendable {
    public private(set) var documents = 0
    public private(set) var checking = 0
    public private(set) var excluded = 0
    public private(set) var pdfs = 0
    public private(set) var jpgs = 0
    public private(set) var pngs = 0
    public private(set) var pageFolders = 0
    public private(set) var pageImages = 0
    public private(set) var standaloneImages = 0

    public init(items: [BatchItem], policy: OutputPolicy, settings: ExportSettings) {
        for item in items {
            guard let metadata = item.validation.metadata else {
                if item.validation == .checking { checking += 1 } else { excluded += 1 }
                continue
            }
            documents += 1
            let format = policy.resolve(for: item.url, settings: settings).format
            let isSeries = metadata.isPDF && format != .pdf
            let count = isSeries ? metadata.pageCount : 1
            switch format {
            case .pdf: pdfs += count
            case .jpg: jpgs += count
            case .png: pngs += count
            }
            if isSeries { pageFolders += 1; pageImages += count }
            else if format != .pdf { standaloneImages += 1 }
        }
    }

    public var actionLabel: String {
        documents == 0 ? "Export documents…" : "Export \(documents) \(documents == 1 ? "document" : "documents")…"
    }

    public var message: String {
        var parts: [String] = []
        if checking > 0 { parts.append("Checking files… Counts below are incomplete.") }
        if documents > 0 {
            let outputs = [(pdfs, "PDF"), (jpgs, "JPG"), (pngs, "PNG")]
                .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)\($0.0 == 1 ? " file" : " files")" }
            parts.append("\(documents) \(documents == 1 ? "document" : "documents") → " + outputs.joined(separator: ", ") + ".")
            if pageFolders > 0 {
                parts.append("\(pageImages) page \(pageImages == 1 ? "image" : "images") in \(pageFolders) separate \(pageFolders == 1 ? "folder" : "folders") (one per PDF).")
                if standaloneImages > 0 {
                    parts.append("\(standaloneImages) \(standaloneImages == 1 ? "image copy" : "image copies") saved outside those folders.")
                }
            }
        } else if checking == 0 {
            parts.append(excluded == 0 ? "Add documents to export marked copies." : "No documents are ready to export.")
        }
        if excluded > 0 { parts.append("\(excluded) invalid \(excluded == 1 ? "document" : "documents") excluded.") }
        return parts.joined(separator: "\n")
    }
}
