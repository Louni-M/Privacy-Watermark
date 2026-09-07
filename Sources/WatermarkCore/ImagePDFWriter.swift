import Foundation
import CoreGraphics

/// A deliberately narrow PDF writer: one opaque RGB JPEG per page. Inserting a
/// JPEG through a graphics context decodes it again to compute image identity.
/// Writing the existing JPEG stream directly preserves its bytes and resolution.
final class ImagePDFWriter {
    struct Page {
        let jpeg: Data
        let pixels: CGSize
        let size: CGSize
    }

    static func write(to url: URL, pageCount: Int, page: (Int) throws -> Page) throws {
        guard pageCount > 0 else { throw DocumentError.invalidPDF }
        guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else { throw DocumentError.writeFailed }
        let file = try FileHandle(forWritingTo: url)
        defer { try? file.close() }
        var offset: UInt64 = 0
        var offsets: [UInt64] = [0]
        func bytes(_ data: Data) throws { try file.write(contentsOf: data); offset += UInt64(data.count) }
        func text(_ value: String) throws { try bytes(Data(value.utf8)) }
        func object(_ number: Int, _ body: String, stream: Data? = nil) throws {
            offsets.append(offset)
            try text("\(number) 0 obj\n\(body)")
            if let stream { try text("\nstream\n"); try bytes(stream); try text("\nendstream") }
            try text("\nendobj\n")
        }
        try text("%PDF-1.4\n%\u{00e2}\u{00e3}\u{00cf}\u{00d3}\n")
        try object(1, "<< /Type /Catalog /Pages 2 0 R >>")
        let children = (0..<pageCount).map { "\(3 + $0 * 3) 0 R" }.joined(separator: " ")
        try object(2, "<< /Type /Pages /Count \(pageCount) /Kids [\(children)] >>")
        for index in 0..<pageCount {
            try Task.checkCancellation()
            try autoreleasepool {
                let item = try page(index)
                guard item.size.width.isFinite, item.size.height.isFinite,
                      item.size.width > 0, item.size.height > 0,
                      item.pixels.width > 0, item.pixels.height > 0 else { throw DocumentError.renderFailed }
                let number = 3 + index * 3
                let width = String(Double(item.size.width)), height = String(Double(item.size.height))
                try object(number, "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 \(width) \(height)] /Resources << /XObject << /Im0 \(number+1) 0 R >> >> /Contents \(number+2) 0 R >>")
                try object(number+1, "<< /Type /XObject /Subtype /Image /Width \(Int(item.pixels.width)) /Height \(Int(item.pixels.height)) /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length \(item.jpeg.count) >>", stream: item.jpeg)
                let commands = Data("q\n\(width) 0 0 \(height) 0 0 cm\n/Im0 Do\nQ\n".utf8)
                try object(number+2, "<< /Length \(commands.count) >>", stream: commands)
            }
        }
        let xrefOffset = offset
        try text("xref\n0 \(offsets.count)\n0000000000 65535 f \n")
        for location in offsets.dropFirst() { try text(String(format: "%010llu 00000 n \n", location)) }
        try text("trailer\n<< /Size \(offsets.count) /Root 1 0 R >>\nstartxref\n\(xrefOffset)\n%%EOF\n")
    }
}
