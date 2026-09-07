import Foundation

public enum SourceValidation {
    private struct Stamp: Equatable {
        let identity: FileIdentity
        let size: UInt64
        let modified: Date
        let created: Date
        init(_ url: URL) throws {
            guard url.isFileURL, FileManager.default.isReadableFile(atPath: url.path),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.resolvingSymlinksInPath().path),
                  attributes[.type] as? FileAttributeType == .typeRegular,
                  let size = attributes[.size] as? NSNumber,
                  let modified = attributes[.modificationDate] as? Date,
                  let created = attributes[.creationDate] as? Date else { throw DocumentError.sourceUnavailable }
            identity = FileIdentity(url)
            self.size = size.uint64Value
            self.modified = modified
            self.created = created
        }
    }

    public static func load(_ url: URL, identity: FileIdentity, validated: ValidatedSource? = nil) throws -> SourceDocument {
        try Task.checkCancellation()
        let before = try Stamp(url)
        guard before.identity == identity else { throw DocumentError.sourceChanged }
        let source = try SourceDocument.load(url)
        try Task.checkCancellation()
        let after = try Stamp(url)
        guard before == after else { throw DocumentError.sourceChanged }
        if let validated {
            guard validated.identity == after.identity,
                  ValidatedSource.hash(source.data) == validated.fingerprint else { throw DocumentError.sourceChanged }
        }
        return source
    }

    public static func inspect(_ item: BatchItem) throws -> ValidatedSource {
        try autoreleasepool {
            if (try? item.url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                throw DocumentError.unsupported
            }
            let source = try load(item.url, identity: item.identity)
            let result = ValidatedSource(source)
            guard result.identity == item.identity else { throw DocumentError.sourceChanged }
            return result
        }
    }

    public static func verify(_ url: URL, identity: FileIdentity, validated: ValidatedSource) throws {
        try Task.checkCancellation()
        let before = try Stamp(url)
        guard before.identity == identity, before.size <= SourceDocument.maximumBytes else { throw DocumentError.sourceChanged }
        let data = try Data(contentsOf: url)
        guard before == (try Stamp(url)), ValidatedSource.hash(data) == validated.fingerprint else {
            throw DocumentError.sourceChanged
        }
        try Task.checkCancellation()
    }

    public static func message(for error: Error) -> String {
        (error as? DocumentError)?.localizedDescription
            ?? "Unable to complete this operation. Check the file, destination, and available disk space, then try again."
    }
}
