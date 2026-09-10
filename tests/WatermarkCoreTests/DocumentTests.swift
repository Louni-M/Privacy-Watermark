import Testing
import PDFKit
import ImageIO
@testable import WatermarkCore

@Suite(.serialized)
final class DocumentTests {
    var temporaryDirectories: [URL] = []
    deinit { for url in temporaryDirectories { try? FileManager.default.removeItem(at: url) } }
    func fixture(_ name: String) -> URL { Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")! }
    func temporary() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        temporaryDirectories.append(url)
        return url
    }
    @Test func testDefaults() throws {
        try WatermarkSettings().validate()
        checkTrue(ExportSettings().flattened)
        checkEqual(ExportSettings().dpi, 450)
    }

    @Test func testSupportedInputsAndLimits() throws {
        for name in ["photo.jpg", "opaque.png", "transparent.png", "oriented.jpg", "document.pdf", "scan.pdf", "pages-50.pdf"] {
            checkGreater(try SourceDocument.load(fixture(name)).pageCount, 0)
        }
        for (name, expected) in [("protected.pdf", DocumentError.protectedPDF), ("corrupt.pdf", .invalidPDF), ("empty.pdf", .invalidPDF), ("pages-51.pdf", .pageLimit)] {
            expectError(try SourceDocument.load(fixture(name))) { checkEqual($0 as? DocumentError, expected) }
        }
        let folder = try temporary()
        let large = folder.appendingPathComponent("large.jpg")
        FileManager.default.createFile(atPath: large.path, contents: nil)
        let file = try FileHandle(forWritingTo: large)
        try file.truncate(atOffset: UInt64(SourceDocument.maximumBytes + 1))
        try file.close()
        expectError(try SourceDocument.load(large)) { checkEqual($0 as? DocumentError, .tooLarge) }
        expectError(try SourceDocument.load(folder.appendingPathComponent("no.gif"))) { checkEqual($0 as? DocumentError, .unsupported) }
    }

    @Test func testImageFormatMatrixAndMetadata() throws {
        let folder = try temporary()
        for name in ["photo.jpg", "opaque.png", "oriented.jpg", "transparent.png"] {
            let source = try SourceDocument.load(fixture(name))
            for format in OutputFormat.allCases {
                var settings = ExportSettings(); settings.format = format
                let output = folder.appendingPathComponent("\(name).\(format.fileExtension)")
                try Processing.export(source, watermark: WatermarkSettings(), settings: settings, destination: output)
                let bytes = try Data(contentsOf: output)
                if format == .pdf {
                    let pdf = try require(PDFDocument(data: bytes))
                    checkEqual(pdf.pageCount, 1)
                    checkEqual(pdf.page(at: 0)?.bounds(for: .mediaBox).width, CGFloat(source.pixelWidth))
                } else {
                    let image = try require(CGImageSourceCreateWithData(bytes as CFData, nil))
                    checkEqual(CGImageSourceGetType(image) as String?, format == .png ? "public.png" : "public.jpeg")
                    let props = try require(CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any])
                    checkEqual(props[kCGImagePropertyPixelWidth] as? Int, source.pixelWidth)
                    checkEqual(props[kCGImagePropertyPixelHeight] as? Int, source.pixelHeight)
                    checkNil(props[kCGImagePropertyGPSDictionary])
                    checkNil(props[kCGImagePropertyExifDictionary])
                    if let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                        checkNil(tiff[kCGImagePropertyTIFFMake]); checkNil(tiff[kCGImagePropertyTIFFDateTime])
                    }
                }
            }
        }
    }

    @Test func testStandardPDFPreservesTextGeometryAndLinks() throws {
        let source = try SourceDocument.load(fixture("document.pdf"))
        let folder = try temporary()
        var settings = ExportSettings(); settings.flattened = false
        let output = folder.appendingPathComponent("standard.pdf")
        try Processing.export(source, watermark: WatermarkSettings(), settings: settings, destination: output)
        let doc = try require(PDFDocument(url: output))
        checkEqual(doc.pageCount, 2)
        checkTrue(doc.string?.contains("SYNTHETIC DOCUMENT") == true)
        checkTrue(doc.string?.contains("COPY") == true)
        checkTrue(doc.string?.contains("VISIBLE NOTE") == true)
        checkTrue(doc.string?.contains("FORM VALUE") == true)
        checkEqual(doc.page(at: 0)?.bounds(for: .mediaBox).size, CGSize(width: 400, height: 280))
        checkEqual(doc.page(at: 1)?.bounds(for: .mediaBox).size, CGSize(width: 320, height: 260))
        checkTrue(doc.page(at: 0)?.annotations.contains { ($0.action as? PDFActionURL)?.url?.absoluteString == "https://example.com" } == true)
        if let capture = ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"] {
            try FileManager.default.createDirectory(atPath: capture, withIntermediateDirectories: true)
            let target = URL(fileURLWithPath: capture).appendingPathComponent("standard.pdf")
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.copyItem(at: output, to: target)
        }
    }

    @Test func testFlattenedPDFAndPageSeriesMatrix() throws {
        let source = try SourceDocument.load(fixture("document.pdf"))
        let folder = try temporary()
        for dpi in [300, 450, 600] {
            for format in OutputFormat.allCases {
                var settings = ExportSettings(); settings.dpi = dpi; settings.format = format
                let destination = format == .pdf ? folder.appendingPathComponent("flat-\(dpi).pdf") : folder
                let urls = try Processing.export(source, watermark: WatermarkSettings(), settings: settings, destination: destination, replaceExisting: true)
                if format == .pdf {
                    let doc = try require(PDFDocument(url: urls[0]))
                    checkEqual(doc.pageCount, 2)
                    checkTrue((doc.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    checkEqual(doc.page(at: 1)?.bounds(for: .mediaBox).size, CGSize(width: 320, height: 260))
                    if let capture = ProcessInfo.processInfo.environment["PASSPORT_TEST_OUTPUT"] {
                        let target = URL(fileURLWithPath: capture).appendingPathComponent("flat-\(dpi).pdf")
                        try? FileManager.default.createDirectory(atPath: capture, withIntermediateDirectories: true)
                        try? FileManager.default.removeItem(at: target)
                        try FileManager.default.copyItem(at: urls[0], to: target)
                    }
                } else {
                    checkEqual(urls.count, 2)
                    checkEqual(urls[0].lastPathComponent, "document_page_001.\(format.fileExtension)")
                    let decoder = try require(CGImageSourceCreateWithURL(urls[1] as CFURL, nil))
                    let image = try require(CGImageSourceCreateImageAtIndex(decoder, 0, nil))
                    checkEqual(image.width, 320); checkEqual(image.height, 260)
                }
            }
        }
    }

    @Test func testRepeatExportUsesOriginalAndLatestSettings() throws {
        let source = try SourceDocument.load(fixture("document.pdf"))
        let original = source.data
        let folder = try temporary()
        let output = folder.appendingPathComponent("out.pdf")
        var settings = ExportSettings(); settings.flattened = false
        var watermark = WatermarkSettings(); watermark.text = "FIRST_MARK"
        try Processing.export(source, watermark: watermark, settings: settings, destination: output)
        watermark.text = "SECOND_MARK"
        _ = try Processing.preview(source, watermark: watermark, export: settings)
        try Processing.export(source, watermark: watermark, settings: settings, destination: output, replaceExisting: true)
        let text = try require(PDFDocument(url: output)?.string)
        checkTrue(text.contains("SECOND_MARK")); checkFalse(text.contains("FIRST_MARK"))
        checkEqual(try Data(contentsOf: source.url), original)
    }

    @Test func testDestinationsProtectSourceAndExistingFiles() throws {
        let folder = try temporary()
        let sourceURL = folder.appendingPathComponent("original.pdf")
        try FileManager.default.copyItem(at: fixture("document.pdf"), to: sourceURL)
        let source = try SourceDocument.load(sourceURL)
        let link = folder.appendingPathComponent("alias.pdf")
        try FileManager.default.linkItem(at: sourceURL, to: link)
        for destination in [sourceURL, link] {
            expectError(try Processing.export(source, watermark: WatermarkSettings(), settings: ExportSettings(), destination: destination, replaceExisting: true)) {
                checkEqual($0 as? DocumentError, .sourceDestination)
            }
        }
        let existing = folder.appendingPathComponent("existing.pdf")
        try Data("existing".utf8).write(to: existing)
        expectError(try Processing.export(source, watermark: WatermarkSettings(), settings: ExportSettings(), destination: existing)) { checkEqual($0 as? DocumentError, .destinationExists) }
        checkEqual(try Data(contentsOf: existing), Data("existing".utf8))
        checkEqual(try Data(contentsOf: sourceURL), source.data)
        checkFalse(try FileManager.default.contentsOfDirectory(atPath: folder.path).contains { $0.hasPrefix(".passport-export-") })
    }

    @Test func testInvalidWatermarkAndInvisiblePreview() throws {
        var settings = WatermarkSettings(); settings.text = String(repeating: "X", count: 201)
        expectError(try settings.validate())
        settings.text = "COPY"; settings.spacing = 0
        expectError(try settings.validate())
        let source = try SourceDocument.load(fixture("photo.jpg"))
        settings = WatermarkSettings(); settings.opacity = 0
        let zero = try Processing.preview(source, watermark: settings, export: ExportSettings())
        settings.opacity = 30; settings.text = ""
        checkEqual(zero, try Processing.preview(source, watermark: settings, export: ExportSettings()))
    }

    @Test func testExactFileAndImageDimensionBoundaries() throws {
        let folder = try temporary()
        let padded = folder.appendingPathComponent("boundary.JPG")
        try Data(contentsOf: fixture("photo.jpg")).write(to: padded)
        let handle = try FileHandle(forWritingTo: padded)
        try handle.truncate(atOffset: UInt64(SourceDocument.maximumBytes))
        try handle.close()
        checkEqual(try SourceDocument.load(padded).pixelWidth, 1000)
        for width in [20_000, 20_001] {
            let context = try Renderer.bitmap(size: CGSize(width: width, height: 1))
            let image = try require(context.makeImage())
            let url = folder.appendingPathComponent("\(width).png")
            try Renderer.encoded(image, format: .png).write(to: url)
            if width == 20_000 { checkEqual(try SourceDocument.load(url).pixelWidth, width) }
            else { expectError(try SourceDocument.load(url)) { checkEqual($0 as? DocumentError, .imageDimensions) } }
        }
    }

    @Test func testAllWatermarkAdjustmentsAndAlphaDiscard() throws {
        let source = try SourceDocument.load(fixture("transparent.png"))
        var watermark = WatermarkSettings(); watermark.opacity = 0
        let clean = try Renderer.renderImage(source, settings: watermark)
        let normalized = try require(CGContext(data: nil, width: clean.width, height: clean.height, bitsPerComponent: 8,
            bytesPerRow: 0, space: Renderer.colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        normalized.draw(clean, in: CGRect(x: 0, y: 0, width: clean.width, height: clean.height))
        let rgb = try require(normalized.makeImage()?.dataProvider?.data) as Data
        checkEqual(Array(rgb.prefix(3)), [UInt8(90), 140, 180])
        watermark.opacity = 30
        watermark.color = .white
        let marked = try Renderer.renderImage(source, settings: watermark)
        normalized.draw(marked, in: CGRect(x: 0, y: 0, width: clean.width, height: clean.height))
        let markedRGB = try require(normalized.makeImage()?.dataProvider?.data) as Data
        // On a fully transparent background the watermark retains its own RGB
        // after alpha is discarded, even when its opacity is below 100%.
        checkTrue(stride(from: 0, to: normalized.bytesPerRow * 30, by: 4).contains {
            markedRGB[$0] > 240 && markedRGB[$0 + 1] > 240 && markedRGB[$0 + 2] > 240
        })
        let baseline = try Renderer.encoded(clean, format: .png)
        var results = Set<Data>()
        for color in WatermarkColor.allCases {
            for direction in WatermarkDirection.allCases {
                watermark.color = color; watermark.direction = direction; watermark.opacity = 100
                watermark.spacing = 50; watermark.size = 12
                let small = try Processing.preview(source, watermark: watermark, export: ExportSettings())
                checkFalse(small == baseline)
                results.insert(small)
                watermark.spacing = 300; watermark.size = 72
                let large = try Processing.preview(source, watermark: watermark, export: ExportSettings())
                checkFalse(large == small)
            }
        }
        checkEqual(results.count, 6)
    }

    @Test func testTransactionRollsBackAllFilesWhenCommitFails() throws {
        let folder = try temporary()
        let outputs = [folder.appendingPathComponent("page1.png"), folder.appendingPathComponent("page2.png")]
        for url in outputs { try Data("original".utf8).write(to: url) }
        let transaction = try OutputTransaction(source: fixture("document.pdf"), outputs: outputs, replaceExisting: true)
        try Data("replacement".utf8).write(to: transaction.staged[0])
        // A missing second staged file fails after the first replacement was made.
        expectError(try transaction.commit())
        transaction.cleanUp()
        for url in outputs { checkEqual(try Data(contentsOf: url), Data("original".utf8)) }
        checkFalse(FileManager.default.fileExists(atPath: transaction.directory.path))
    }

    @Test func testSymlinkDestinationCannotReplaceSource() throws {
        let folder = try temporary()
        let sourceURL = folder.appendingPathComponent("original.png")
        try FileManager.default.copyItem(at: fixture("opaque.png"), to: sourceURL)
        let link = folder.appendingPathComponent("link.png")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: sourceURL)
        let source = try SourceDocument.load(sourceURL)
        var settings = ExportSettings(); settings.format = .png
        expectError(try Processing.export(source, watermark: WatermarkSettings(), settings: settings, destination: link, replaceExisting: true)) {
            checkEqual($0 as? DocumentError, .sourceDestination)
        }
        checkEqual(try Data(contentsOf: sourceURL), source.data)
    }

    @Test func testMetadataRemovalRejectsBrokenEncodedContainers() throws {
        expectError(try ImageMetadata.removingAncillaryMetadata(Data([0xff,0xd8,0xff,0xe1,0xff,0xff]), format: .jpg))
        expectError(try ImageMetadata.removingAncillaryMetadata(Data([137,80,78,71,13,10,26,10,0,0,0,100,101,88,73,102,0,0,0,0]), format: .png))
    }
}

private func checkEqual<T: Equatable>(_ a: T, _ b: T, sourceLocation: SourceLocation = #_sourceLocation) { #expect(a == b, sourceLocation: sourceLocation) }
private func checkTrue(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) { #expect(value, sourceLocation: sourceLocation) }
private func checkFalse(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) { #expect(!value, sourceLocation: sourceLocation) }
private func checkNil<T>(_ value: T?, sourceLocation: SourceLocation = #_sourceLocation) { #expect(value == nil, sourceLocation: sourceLocation) }
private func checkGreater<T: Comparable>(_ a: T, _ b: T, sourceLocation: SourceLocation = #_sourceLocation) { #expect(a > b, sourceLocation: sourceLocation) }
private func require<T>(_ value: T?, sourceLocation: SourceLocation = #_sourceLocation) throws -> T { try #require(value, sourceLocation: sourceLocation) }
private func expectError<T>(_ expression: @autoclosure () throws -> T, sourceLocation: SourceLocation = #_sourceLocation, check: (Error) -> Void = { _ in }) {
    do { _ = try expression(); Issue.record("Expected an error", sourceLocation: sourceLocation) } catch { check(error) }
}
