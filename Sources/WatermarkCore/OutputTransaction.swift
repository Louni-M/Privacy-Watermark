import Foundation

final class OutputTransaction {
    let source: URL
    let outputs: [URL]
    let staged: [URL]
    let directory: URL
    let replaceExisting: Bool
    private var backups: [(URL, URL)] = []
    private var committed: [URL] = []
    private let files = FileManager.default

    init(source: URL, outputs: [URL], replaceExisting: Bool) throws {
        self.source = source
        self.outputs = outputs
        self.replaceExisting = replaceExisting
        guard let parent = outputs.first?.deletingLastPathComponent() else { throw DocumentError.writeFailed }
        let stagingDirectory = parent.appendingPathComponent(".passport-export-\(UUID().uuidString)", isDirectory: true)
        directory = stagingDirectory
        staged = outputs.indices.map { stagingDirectory.appendingPathComponent("page-\($0)") }
        try preflight()
        try files.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    }

    private func isSource(_ url: URL) -> Bool {
        if source.resolvingSymlinksInPath().standardizedFileURL == url.resolvingSymlinksInPath().standardizedFileURL { return true }
        if let a = try? files.attributesOfItem(atPath: source.path), let b = try? files.attributesOfItem(atPath: url.path),
           let inodeA = a[.systemFileNumber] as? NSNumber, let inodeB = b[.systemFileNumber] as? NSNumber,
           let deviceA = a[.systemNumber] as? NSNumber, let deviceB = b[.systemNumber] as? NSNumber {
            return inodeA == inodeB && deviceA == deviceB
        }
        return false
    }

    private func preflight() throws {
        for url in outputs {
            guard !isSource(url) else { throw DocumentError.sourceDestination }
            var isDirectory: ObjCBool = false
            if files.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                guard !isDirectory.boolValue else { throw DocumentError.writeFailed }
                guard replaceExisting else { throw DocumentError.destinationExists }
            }
        }
    }

    func commit() throws {
        try preflight()
        do {
            for (index, output) in outputs.enumerated() {
                if files.fileExists(atPath: output.path) {
                    let backup = directory.appendingPathComponent("backup-\(index)")
                    try files.moveItem(at: output, to: backup)
                    backups.append((backup, output))
                }
                try files.moveItem(at: staged[index], to: output)
                committed.append(output)
            }
        } catch {
            for output in committed.reversed() { try? files.removeItem(at: output) }
            for (backup, output) in backups.reversed() { try? files.moveItem(at: backup, to: output) }
            // If rollback cannot restore a file, retain its backup rather than deleting it.
            throw DocumentError.writeFailed
        }
        backups.removeAll()
    }

    func cleanUp() {
        let unRestored = backups.contains { files.fileExists(atPath: $0.0.path) }
        if !unRestored { try? files.removeItem(at: directory) }
    }
}
