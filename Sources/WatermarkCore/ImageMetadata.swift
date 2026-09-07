import Foundation

enum ImageMetadata {
    /// ImageIO synthesizes EXIF even from a fresh bitmap. Remove ancillary metadata
    /// segments from its output without decoding/recompressing the pixels again.
    static func removingAncillaryMetadata(_ data: Data, format: OutputFormat) throws -> Data {
        let bytes = [UInt8](data)
        if format == .png {
            guard bytes.count >= 8, Array(bytes.prefix(8)) == [137,80,78,71,13,10,26,10] else { throw DocumentError.writeFailed }
            var result = Data(bytes.prefix(8))
            var offset = 8
            while offset + 12 <= bytes.count {
                let length = Int(bytes[offset]) << 24 | Int(bytes[offset+1]) << 16 | Int(bytes[offset+2]) << 8 | Int(bytes[offset+3])
                guard length <= bytes.count - offset - 12 else { throw DocumentError.writeFailed }
                let type = String(bytes: bytes[(offset+4)..<(offset+8)], encoding: .ascii)
                let end = offset + length + 12
                if !["eXIf", "tEXt", "iTXt", "zTXt", "tIME"].contains(type ?? "") {
                    result.append(contentsOf: bytes[offset..<end])
                }
                offset = end
            }
            guard offset == bytes.count else { throw DocumentError.writeFailed }
            return result
        }
        guard bytes.count >= 4, bytes[0] == 0xff, bytes[1] == 0xd8 else { throw DocumentError.writeFailed }
        var result = Data(bytes.prefix(2))
        var offset = 2
        while offset + 4 <= bytes.count {
            guard bytes[offset] == 0xff else { throw DocumentError.writeFailed }
            let marker = bytes[offset + 1]
            if marker == 0xda { // Compressed scan data is copied byte-for-byte.
                result.append(contentsOf: bytes[offset...])
                return result
            }
            let length = Int(bytes[offset+2]) << 8 | Int(bytes[offset+3])
            guard length >= 2, length <= bytes.count - offset - 2 else { throw DocumentError.writeFailed }
            let end = offset + length + 2
            if ![UInt8(0xe1), 0xed, 0xfe].contains(marker) { result.append(contentsOf: bytes[offset..<end]) }
            offset = end
        }
        throw DocumentError.writeFailed
    }
}
