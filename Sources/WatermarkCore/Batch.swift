import Foundation
import CryptoKit

public enum OutputPolicy: String, CaseIterable, Sendable {
    case original = "Keep original format", pdf = "PDF", jpg = "JPG", png = "PNG"

    public func resolve(for url: URL, settings: ExportSettings) -> ExportSettings {
        var result = settings
        switch self {
        case .pdf: result.format = .pdf
        case .jpg: result.format = .jpg
        case .png: result.format = .png
        case .original:
            switch url.pathExtension.lowercased() {
            case "pdf": result.format = .pdf
            case "png": result.format = .png
            default: result.format = .jpg
            }
        }
        return result
    }
}

public struct FileIdentity: Equatable, Hashable, Sendable {
    public let value: String
    public init(_ url: URL) {
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL
        if let attributes = try? FileManager.default.attributesOfItem(atPath: canonical.path),
           let device = attributes[.systemNumber] as? NSNumber,
           let inode = attributes[.systemFileNumber] as? NSNumber {
            value = "\(device):\(inode)"
        } else {
            value = canonical.absoluteString
        }
    }
}

public struct ValidatedSource: Equatable, Sendable {
    public let identity: FileIdentity
    public let fingerprint: String
    public let pageCount: Int
    public let isPDF: Bool
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(_ source: SourceDocument) {
        identity = FileIdentity(source.url)
        fingerprint = Self.hash(source.data)
        pageCount = source.pageCount
        isPDF = source.kind == .pdf
        pixelWidth = source.pixelWidth
        pixelHeight = source.pixelHeight
    }

    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public enum ValidationState: Equatable, Sendable {
    case checking
    case ready(ValidatedSource)
    case invalid(String)
    public var metadata: ValidatedSource? {
        if case .ready(let value) = self { value } else { nil }
    }
}

public enum ExportState: Equatable, Sendable {
    case idle, pending, exporting, saved([URL]), failed(String), unprocessed
}

public struct BatchItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let identity: FileIdentity
    public var validation: ValidationState = .checking
    public var export: ExportState = .idle
    public init(url: URL) {
        id = UUID()
        self.url = url.standardizedFileURL
        identity = FileIdentity(url)
    }
}

/// Value-only collection: no row owns a decoded source or a preview.
public struct BatchCollection: Sendable {
    public private(set) var items: [BatchItem] = []
    public private(set) var selectedID: UUID?
    public init() {}

    public var selected: BatchItem? { items.first { $0.id == selectedID } }
    public var checkingCount: Int { items.filter { $0.validation == .checking }.count }
    public var readyCount: Int { items.filter { $0.validation.metadata != nil }.count }

    @discardableResult public mutating func append(_ urls: [URL]) -> Int {
        var duplicates = 0
        var identities = Set(items.map(\.identity))
        for url in urls {
            let item = BatchItem(url: url)
            guard identities.insert(item.identity).inserted else { duplicates += 1; continue }
            items.append(item)
            if selectedID == nil { selectedID = item.id }
        }
        return duplicates
    }

    public mutating func select(_ id: UUID) {
        if items.contains(where: { $0.id == id }) { selectedID = id }
    }

    public mutating func update(_ id: UUID, _ body: (inout BatchItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        body(&items[index])
    }

    public mutating func remove(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items.remove(at: index)
        if selectedID == id {
            selectedID = items.isEmpty ? nil : items[min(index, items.count - 1)].id
        }
    }

    public mutating func clear() { items.removeAll(); selectedID = nil }
}
