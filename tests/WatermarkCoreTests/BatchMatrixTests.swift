import Foundation
import ImageIO
import PDFKit
import Testing
@testable import WatermarkCore

@Suite(.serialized)
struct BatchMatrixTests {
    @Test func mixedPolicyModeAndEncodingMatrix() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var items: [BatchItem] = []
        var originals: [Data] = []
        for name in ["photo.jpg", "oriented.jpg", "opaque.png", "transparent.png", "document.pdf"] {
            let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")!
            var item = BatchItem(url: url)
            item.validation = .ready(try SourceValidation.inspect(item))
            items.append(item)
            originals.append(try Data(contentsOf: url))
        }
        for policy in OutputPolicy.allCases {
            for mode in [0, 300, 450, 600] {
                var settings = ExportSettings()
                settings.flattened = mode != 0
                settings.dpi = mode == 0 ? 450 : mode
                let folder = root.appendingPathComponent("\(policy.rawValue)-\(mode)")
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
                let result = await BatchExport.run(items: items, watermark: WatermarkSettings(), policy: policy,
                    settings: settings, destination: folder, update: { _, _, _ in })
                #expect(result.saved == items.count && result.failed == 0)
                for (index, item) in items.enumerated() {
                    let format = policy.resolve(for: item.url, settings: settings).format
                    let series = item.validation.metadata!.isPDF && format != .pdf
                    let stem = item.url.deletingPathExtension().lastPathComponent
                    let destination = folder.appendingPathComponent(stem + "_watermarked" + (series ? "" : "." + format.fileExtension))
                    if format == .pdf {
                        let pdf = try #require(PDFDocument(url: destination))
                        #expect(pdf.pageCount == item.validation.metadata!.pageCount)
                        if item.validation.metadata!.isPDF {
                            #expect((pdf.string ?? "").contains("SYNTHETIC DOCUMENT") == !settings.flattened)
                        }
                    } else {
                        let outputs = series
                            ? (1...item.validation.metadata!.pageCount).map { destination.appendingPathComponent(String(format: "%@_page_%03d.%@", stem, $0, format.fileExtension)) }
                            : [destination]
                        for output in outputs {
                            let bytes = try Data(contentsOf: output)
                            let encoded = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
                            #expect(CGImageSourceGetType(encoded) as String? == (format == .png ? "public.png" : "public.jpeg"))
                            let properties = try #require(CGImageSourceCopyPropertiesAtIndex(encoded, 0, nil) as? [CFString: Any])
                            #expect(properties[kCGImagePropertyGPSDictionary] == nil)
                            #expect(properties[kCGImagePropertyExifDictionary] == nil)
                        }
                    }
                    #expect(try Data(contentsOf: item.url) == originals[index])
                }
            }
        }
    }
}
