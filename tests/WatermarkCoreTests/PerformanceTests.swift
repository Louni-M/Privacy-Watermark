import Foundation
import Testing
import PDFKit
@testable import WatermarkCore

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["PASSPORT_BENCHMARK_OUTPUT"] != nil))
struct PerformanceTests {
    @Test func recordProcessingMatrix() throws {
        let output = URL(fileURLWithPath: ProcessInfo.processInfo.environment["PASSPORT_BENCHMARK_OUTPUT"]!)
        let fixtureRoot = Bundle.module.url(forResource: "Fixtures", withExtension: nil)!
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var timings: [String: [Double]] = [:]
        let watermark = WatermarkSettings()
        func measure(_ key: String, run: () throws -> Void) throws {
            var samples: [Double] = []
            for _ in 0..<10 {
                let start = ContinuousClock.now
                try autoreleasepool { try run() }
                let duration = start.duration(to: .now).components
                samples.append(Double(duration.seconds) + Double(duration.attoseconds) / 1e18)
            }
            timings[key] = samples
        }
        for file in ["photo.jpg", "opaque.png", "oriented.jpg", "transparent.png"] {
            let source = try SourceDocument.load(fixtureRoot.appendingPathComponent(file))
            for format in OutputFormat.allCases {
                var settings = ExportSettings(); settings.format = format
                let url = output.appendingPathComponent("\(file)-\(format.rawValue).\(format.fileExtension)")
                try measure("\(file)/\(format.rawValue)") {
                    try Processing.export(source, watermark: watermark, settings: settings, destination: url, replaceExisting: true)
                }
            }
        }
        for file in ["document.pdf", "scan.pdf", "pages-10.pdf"] {
            let source = try SourceDocument.load(fixtureRoot.appendingPathComponent(file))
            try measure("\(file)/preview") { _ = try Processing.preview(source, watermark: watermark, export: ExportSettings()) }
            for mode in ["standard", "300", "450", "600"] {
                for format in OutputFormat.allCases {
                    var settings = ExportSettings()
                    settings.format = format
                    settings.flattened = mode != "standard"
                    settings.dpi = Int(mode) ?? 450
                    let folder = output.appendingPathComponent("\(file)-\(mode)-\(format.rawValue)")
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    try measure("\(file)/\(mode)/\(format.rawValue)") {
                        try Processing.export(source, watermark: watermark, settings: settings,
                            destination: format == .pdf ? folder.appendingPathComponent("output.pdf") : folder, replaceExisting: true)
                    }
                }
            }
        }
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let report: [String: Any] = ["seconds": timings, "max_rss_bytes": usage.ru_maxrss,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "method": "Release processing tests; 10 repetitions per route; same synthetic fixtures and settings as Python reference. Includes transactional output writing."]
        let bytes = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try bytes.write(to: output.appendingPathComponent("native-processing.json"))
    }

    @Test func recordFiftyPageStress() throws {
        let output = URL(fileURLWithPath: ProcessInfo.processInfo.environment["PASSPORT_BENCHMARK_OUTPUT"]!)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let source = try SourceDocument.load(Bundle.module.url(forResource: "pages-50", withExtension: "pdf", subdirectory: "Fixtures")!)
        var settings = ExportSettings(); settings.dpi = 600
        let start = ContinuousClock.now
        let url = output.appendingPathComponent("stress-50-pages-600.pdf")
        try Processing.export(source, watermark: WatermarkSettings(), settings: settings, destination: url, replaceExisting: true)
        let elapsed = start.duration(to: .now).components
        let pdf = try #require(PDFDocument(url: url))
        #expect(pdf.pageCount == 50)
        #expect((pdf.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        var usage = rusage(); getrusage(RUSAGE_SELF, &usage)
        let report: [String: Any] = ["pages": 50, "dpi": 600, "seconds": Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18,
            "max_rss_bytes": usage.ru_maxrss, "output_bytes": (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber) ?? 0]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("native-stress.json"))
    }
}
