import Foundation
import CryptoKit
import PDFKit
import Testing
@testable import WatermarkCore

/// Native, reproducible workload. Existing PDFs retain their text, scan,
/// annotation and rotation cases; each copy has a distinct filesystem identity.
enum BatchCorpus {
    static let subsetIndices = [0, 1, 2, 3, 40, 41, 42, 70, 71, 73]

    static func generate(at root: URL) throws -> [[String: Any]] {
        let files = FileManager.default
        try files.createDirectory(at: root, withIntermediateDirectories: true)
        let fixtures = Bundle.module.url(forResource: "Fixtures", withExtension: nil)!
        let large = try Renderer.bitmap(size: CGSize(width: 4000, height: 3000))
        for index in 0..<120 {
            large.setFillColor(CGColor(red: CGFloat(index % 7) / 7,
                green: CGFloat(index % 11) / 11, blue: CGFloat(index % 13) / 13, alpha: 1))
            large.fill(CGRect(x: (index % 12) * 334, y: (index / 12) * 300, width: 334, height: 300))
        }
        guard let image = large.makeImage() else { throw DocumentError.renderFailed }
        let largeJPEG = try Renderer.encoded(image, format: .jpg)
        let largePNG = try Renderer.encoded(image, format: .png)
        var records: [[String: Any]] = []
        for index in 0..<100 {
            try autoreleasepool {
                let ext: String
                let bytes: Data
                let origin: String
                if index < 40 {
                    ext = index.isMultiple(of: 2) ? "jpg" : "jpeg"
                    origin = index < 4 ? "native-12mp" : (index.isMultiple(of: 2) ? "photo.jpg" : "oriented.jpg")
                    bytes = index < 4 ? largeJPEG : try Data(contentsOf: fixtures.appendingPathComponent(origin))
                } else if index < 70 {
                    ext = "png"
                    origin = index < 42 ? "native-12mp" : (index.isMultiple(of: 2) ? "opaque.png" : "transparent.png")
                    bytes = index < 42 ? largePNG : try Data(contentsOf: fixtures.appendingPathComponent(origin))
                } else {
                    ext = "pdf"
                    origin = ["document.pdf", "scan.pdf", "pages-10.pdf", "pages-50.pdf"][(index - 70) % 4]
                    bytes = try Data(contentsOf: fixtures.appendingPathComponent(origin))
                }
                let name = String(format: "%03d.%@", index, ext)
                let url = root.appendingPathComponent(name)
                try bytes.write(to: url, options: .withoutOverwriting)
                let source = try SourceDocument.load(url)
                let attributes = try files.attributesOfItem(atPath: url.path)
                var geometry: [[String: Any]] = []
                if let pdf = source.kind == .pdf ? PDFDocument(data: bytes) : nil {
                    for pageIndex in 0..<pdf.pageCount {
                        guard let page = pdf.page(at: pageIndex) else { throw DocumentError.invalidPDF }
                        let size = Renderer.pageSize(page)
                        geometry.append(["width": size.width, "height": size.height, "rotation": page.rotation,
                            "crop": NSStringFromRect(page.bounds(for: .cropBox))])
                    }
                } else {
                    geometry = [["width": source.pixelWidth, "height": source.pixelHeight]]
                }
                records.append(["name": name, "origin": origin, "bytes": bytes.count,
                    "sha256": SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
                    "device": attributes[.systemNumber]!, "inode": attributes[.systemFileNumber]!,
                    "pages": source.pageCount, "geometry": geometry, "subset": subsetIndices.contains(index)])
            }
        }
        let manifest: [String: Any] = ["files": records,
            "subset": subsetIndices.map { records[$0]["name"]! },
            "method": "Native CoreGraphics/ImageIO 4000x3000 images and byte-preserving copies of retained synthetic fixtures. No random content or timestamps. Filesystem identities vary by generation; bytes and geometry must agree on the same platform."]
        try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys, .prettyPrinted])
            .write(to: root.appendingPathComponent("manifest.json"), options: .withoutOverwriting)
        return records
    }
}

@Suite(.serialized)
struct BatchCorpusTests {
    @Test func deterministicMixedCorpus() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = try BatchCorpus.generate(at: root.appendingPathComponent("first"))
        let second = try BatchCorpus.generate(at: root.appendingPathComponent("second"))
        #expect(first.count == 100)
        #expect(first.filter { $0["subset"] as? Bool == true }.count == 10)
        #expect(Set(first.compactMap { ($0["inode"] as? NSNumber)?.stringValue }).count == 100)
        #expect(first.compactMap { $0["sha256"] as? String } == second.compactMap { $0["sha256"] as? String })
        #expect(first.filter { $0["origin"] as? String == "native-12mp" }.count == 6)
        #expect(first[73]["pages"] as? Int == 50)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["PASSPORT_CORPUS_OUTPUT"] != nil))
    func recordCorpus() throws {
        let path = ProcessInfo.processInfo.environment["PASSPORT_CORPUS_OUTPUT"]!
        _ = try BatchCorpus.generate(at: URL(fileURLWithPath: path))
    }
}
