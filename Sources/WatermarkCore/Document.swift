import Foundation
import ImageIO
import PDFKit

public enum DocumentError: Error, LocalizedError, Equatable, Sendable {
    case unsupported, tooLarge, imageDimensions, pageLimit, protectedPDF, invalidImage, invalidPDF
    case invalidSettings, invalidPage, sourceChanged, sourceUnavailable, renderFailed, writeFailed, sourceDestination, destinationExists

    public var errorDescription: String? {
        switch self {
        case .unsupported: "Choose a JPG, PNG, or PDF file."
        case .tooLarge: "This file is too large. The maximum size is 100 MB."
        case .imageDimensions: "This image is too large. Each side must be at most 20,000 pixels."
        case .pageLimit: "This PDF has too many pages. The maximum is 50 pages."
        case .protectedPDF: "This PDF is password-protected and cannot be opened."
        case .invalidImage: "Unable to read this image file."
        case .invalidPDF: "Unable to read this PDF file, or it has no pages."
        case .invalidSettings: "Check the watermark settings. Text must be at most 200 characters."
        case .invalidPage: "This page is unavailable. Select a page within the document."
        case .sourceChanged: "This file changed. Remove and add this file again to review the new content."
        case .sourceUnavailable: "This file is unavailable or unreadable. Restore access, then remove and add this file again."
        case .renderFailed: "Unable to render this document. Try a lower export quality or a smaller file."
        case .writeFailed: "Unable to save the output. Check the destination and available disk space."
        case .sourceDestination: "Choose a different destination to keep your original file unchanged."
        case .destinationExists: "Some output files already exist. Confirm replacement or choose another destination."
        }
    }
}

public enum WatermarkColor: String, CaseIterable, Sendable, Codable {
    case white = "White", black = "Black", gray = "Gray"
    var component: CGFloat { self == .white ? 1 : self == .black ? 0 : 0.5 }
}
public enum WatermarkDirection: String, CaseIterable, Sendable, Codable {
    case ascending = "Ascending ↗", descending = "Descending ↘"
    var angle: CGFloat { self == .ascending ? .pi / 4 : -.pi / 4 }
}
public struct WatermarkSettings: Equatable, Sendable, Codable {
    public var text = "COPY"
    public var opacity = 30.0
    public var size = 36.0
    public var spacing = 150.0
    public var color = WatermarkColor.black
    public var direction = WatermarkDirection.ascending
    public init() {}

    public func validate() throws {
        guard text.count <= 200, opacity.isFinite, size.isFinite, spacing.isFinite,
              (0...100).contains(opacity), (12...72).contains(size), (50...300).contains(spacing)
        else { throw DocumentError.invalidSettings }
    }
}
public enum OutputFormat: String, CaseIterable, Sendable, Codable {
    case jpg = "JPG", png = "PNG", pdf = "PDF"
    public var fileExtension: String { rawValue.lowercased() }
}
public struct ExportSettings: Equatable, Sendable {
    public var format = OutputFormat.pdf
    public var flattened = true
    public var dpi = 450
    public init() {}
    public func validate() throws {
        guard [300, 450, 600].contains(dpi) else { throw DocumentError.invalidSettings }
    }
}

/// Only bytes and value types cross operation boundaries, never a mutable PDFDocument.
public struct SourceDocument: Sendable {
    public enum Kind: Sendable { case image, pdf }
    public let url: URL
    public let data: Data
    public let kind: Kind
    public let pageCount: Int
    public let pixelWidth: Int
    public let pixelHeight: Int
    let decodedImage: CGImage?
    let transparentImage: CGImage?
    public static let maximumBytes = 100 * 1024 * 1024

    public static func load(_ url: URL) throws -> SourceDocument {
        let ext = url.pathExtension.lowercased()
        guard ["jpg", "jpeg", "png", "pdf"].contains(ext) else { throw DocumentError.unsupported }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attrs[.size] as? NSNumber, size.int64Value <= maximumBytes else { throw DocumentError.tooLarge }
        let data = try Data(contentsOf: url)
        guard data.count <= maximumBytes else { throw DocumentError.tooLarge }
        if ext == "pdf" {
            guard let pdf = PDFDocument(data: data) else { throw DocumentError.invalidPDF }
            guard !pdf.isEncrypted else { throw DocumentError.protectedPDF }
            guard pdf.pageCount > 0 else { throw DocumentError.invalidPDF }
            guard pdf.pageCount <= 50 else { throw DocumentError.pageLimit }
            return SourceDocument(url: url, data: data, kind: .pdf, pageCount: pdf.pageCount, pixelWidth: 0, pixelHeight: 0, decodedImage: nil, transparentImage: nil)
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw DocumentError.invalidImage }
        guard width <= 20_000, height <= 20_000 else { throw DocumentError.imageDimensions }
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw DocumentError.invalidImage }
        // Decode once into an immutable image snapshot, so every slider adjustment
        // and export does not decompress the same original again.
        let context = try Renderer.bitmap(size: CGSize(width: width, height: height))
        context.draw(Renderer.opaqueImage(image), in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let decoded = context.makeImage() else { throw DocumentError.invalidImage }
        let hasAlpha = [.first, .last, .premultipliedFirst, .premultipliedLast].contains(image.alphaInfo)
        return SourceDocument(url: url, data: data, kind: .image, pageCount: 1, pixelWidth: width, pixelHeight: height, decodedImage: decoded, transparentImage: hasAlpha ? image : nil)
    }
}
