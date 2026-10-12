import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import PWMCommand
import WatermarkCore

/// Synthetic documents only: no personal file ever enters a test.
struct Workspace {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("pwm-\(UUID().uuidString)", isDirectory: true)
            .resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func remove() { try? FileManager.default.removeItem(at: root) }

    func url(_ path: String) -> URL { root.appendingPathComponent(path) }

    func folder(_ path: String) throws -> URL {
        let url = url(path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult func image(_ path: String, width: Int = 320, height: Int = 200, gps: Bool = false) throws -> URL {
        let url = url(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        let type = url.pathExtension.lowercased() == "png" ? UTType.png : UTType.jpeg
        let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)!
        var properties: [CFString: Any] = [:]
        if gps {
            properties[kCGImagePropertyGPSDictionary] = [kCGImagePropertyGPSLatitude: 48.8566, kCGImagePropertyGPSLatitudeRef: "N",
                                                         kCGImagePropertyGPSLongitude: 2.3522, kCGImagePropertyGPSLongitudeRef: "E"]
            properties[kCGImagePropertyExifDictionary] = [kCGImagePropertyExifDateTimeOriginal: "2026:10:12 09:41:00"]
            properties[kCGImagePropertyTIFFDictionary] = [kCGImagePropertyTIFFMake: "FixtureCam", kCGImagePropertyTIFFModel: "One"]
        }
        CGImageDestinationAddImage(destination, context.makeImage()!, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw DocumentError.writeFailed }
        return url
    }

    @discardableResult func pdf(_ path: String, pages: Int = 2, password: String? = nil) throws -> URL {
        let url = url(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var box = CGRect(x: 0, y: 0, width: 300, height: 400)
        var info: [CFString: Any] = [:]
        if let password { info[kCGPDFContextUserPassword] = password; info[kCGPDFContextOwnerPassword] = password }
        let context = CGContext(url as CFURL, mediaBox: &box, info as CFDictionary)!
        for page in 0..<pages {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: CGFloat(page % 5) / 5, alpha: 1))
            context.fill(CGRect(x: 40, y: 40, width: 220, height: 320))
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }

    @discardableResult func text(_ path: String, _ contents: String = "plain text") throws -> URL {
        let url = url(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url)
        return url
    }

    /// Every entry below the root, relative, so tests can assert nothing else appeared.
    func listing() -> [String] {
        let enumerator = FileManager.default.enumerator(atPath: root.path)
        return (enumerator?.allObjects as? [String] ?? []).sorted()
    }
}

func sha256(_ url: URL) throws -> String {
    SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
}

final class Lines: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String] = []
    func append(_ value: String) { lock.withLock { values.append(value) } }
    var all: [String] { lock.withLock { values } }
    var text: String { all.joined(separator: "\n") }
}

struct Outcome {
    let status: CommandStatus
    let output: [String]
    let errors: [String]
    var errorText: String { errors.joined(separator: "\n") }
}

func runCommand(_ arguments: [String], environment: [String: String] = [:], in directory: URL? = nil,
                boundary: @escaping @Sendable (UUID, ExportBoundary) throws -> Void = { _, _ in }) async -> Outcome {
    let out = Lines(), err = Lines()
    var command = Command(environment: environment, currentDirectory: directory ?? FileManager.default.temporaryDirectory,
                          standardOutput: out.append, standardError: err.append)
    command.boundary = boundary
    let status = await command.run(arguments)
    return Outcome(status: status, output: out.all, errors: err.all)
}
