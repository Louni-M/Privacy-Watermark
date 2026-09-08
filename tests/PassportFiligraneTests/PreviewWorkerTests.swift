import Foundation
import Testing
import WatermarkCore
@testable import PassportFiligrane

struct PreviewWorkerTests {
    @Test func cacheBoundRevisionAndSourceOwnership() async throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WatermarkCoreTests/Fixtures/pages-50.pdf")
        var item = BatchItem(url: url)
        item.validation = .ready(try SourceValidation.inspect(item))
        let worker = PreviewWorker()
        for page in 0..<20 {
            let key = PreviewKey(itemID: item.id, fingerprint: item.validation.metadata!.fingerprint, page: page,
                revision: 0, watermark: WatermarkSettings(), output: ExportSettings(),
                viewport: PreviewViewport(region: CGRect(x: 0, y: 0, width: 400, height: 280), scale: 4))
            _ = try await worker.render(item, key: key)
            #expect(await worker.cacheBytes <= PreviewWorker.maximumCacheBytes)
        }
        #expect(await worker.sourceID == item.id)
        let revised = PreviewKey(itemID: item.id, fingerprint: item.validation.metadata!.fingerprint, page: 0,
            revision: 1, watermark: WatermarkSettings(), output: ExportSettings(),
            viewport: PreviewViewport(region: CGRect(x: 0, y: 0, width: 400, height: 280), scale: 1))
        _ = try await worker.render(item, key: revised)
        #expect(await worker.cacheBytes < 1_000_000)
        await worker.clear()
        #expect(await worker.cacheBytes == 0)
        #expect(await worker.sourceID == nil)
    }
    @Test func cancellationAndRenderFailureRecover() async throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WatermarkCoreTests/Fixtures/document.pdf")
        var item = BatchItem(url: url)
        item.validation = .ready(try SourceValidation.inspect(item))
        let worker = PreviewWorker()
        let key = PreviewKey(itemID: item.id, fingerprint: item.validation.metadata!.fingerprint, page: 0,
            revision: 0, watermark: WatermarkSettings(), output: ExportSettings(),
            viewport: PreviewViewport(region: CGRect(x: 0, y: 0, width: 400, height: 280), scale: 1))
        let task = Task { [item] in try Task.checkCancellation(); return try await worker.render(item, key: key) }
        task.cancel()
        do { _ = try await task.value } catch is CancellationError { }
        let invalid = PreviewKey(itemID: item.id, fingerprint: item.validation.metadata!.fingerprint, page: 99,
            revision: 1, watermark: WatermarkSettings(), output: ExportSettings(), viewport: key.viewport)
        do { _ = try await worker.render(item, key: invalid); Issue.record("Expected invalid page failure") }
        catch { #expect(error as? DocumentError == .invalidPage) }
        #expect(try await !worker.render(item, key: key).isEmpty)
        #expect(await worker.cacheBytes <= PreviewWorker.maximumCacheBytes)
    }

}
