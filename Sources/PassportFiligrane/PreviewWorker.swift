import Foundation
import WatermarkCore

struct PreviewKey: Equatable, Sendable {
    let itemID: UUID
    let fingerprint: String
    let page: Int
    let revision: Int
    let watermark: WatermarkSettings
    let output: ExportSettings
    let viewport: PreviewViewport
}

actor PreviewWorker {
    private var source: SourceDocument?
    private(set) var sourceID: UUID?
    private var cache: [(PreviewKey, Data, Int)] = []
    private(set) var cacheBytes = 0
    static let maximumCacheBytes = 96 * 1024 * 1024

    func clear() { source = nil; sourceID = nil; cache.removeAll(); cacheBytes = 0 }

    private func load(_ item: BatchItem) throws -> SourceDocument {
        guard let metadata = item.validation.metadata else { throw DocumentError.sourceUnavailable }
        if sourceID == item.id, let source {
            try SourceValidation.verify(item.url, identity: item.identity, validated: metadata)
            return source
        }
        source = nil
        sourceID = nil
        let loaded = try SourceValidation.load(item.url, identity: item.identity, validated: metadata)
        try Task.checkCancellation()
        source = loaded
        sourceID = item.id
        return loaded
    }

    func size(_ item: BatchItem, page: Int) throws -> CGSize {
        try PreviewRendering.pageSize(load(item), pageIndex: page)
    }

    func render(_ item: BatchItem, key: PreviewKey) throws -> Data {
        let source = try load(item)
        cache.removeAll { $0.0.revision != key.revision }
        cacheBytes = cache.reduce(0) { $0 + $1.2 }
        if let index = cache.firstIndex(where: { $0.0 == key }) {
            let entry = cache.remove(at: index); cache.append(entry)
            try Task.checkCancellation()
            return entry.1
        }
        let bytes = try PreviewRendering.render(source, pageIndex: key.page, watermark: key.watermark,
            export: key.output, viewport: key.viewport)
        try Task.checkCancellation()
        let scale = key.viewport.scale * key.viewport.backingScale
        let pixelCost = min(Double(PreviewRendering.maximumPixels),
            ceil(key.viewport.region.width * scale) * ceil(key.viewport.region.height * scale)) * 4
        let cost = bytes.count + Int(pixelCost)
        while cacheBytes + cost > Self.maximumCacheBytes && !cache.isEmpty {
            cacheBytes -= cache.removeFirst().2
        }
        if cost <= Self.maximumCacheBytes { cache.append((key, bytes, cost)); cacheBytes += cost }
        return bytes
    }
}
