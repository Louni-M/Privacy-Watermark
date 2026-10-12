import Foundation
import WatermarkCore

/// The whole command with its environment injected, so tests never touch real streams.
public struct Command: Sendable {
    public var environment: [String: String]
    public var today: Date
    public var currentDirectory: URL
    public var standardOutput: @Sendable (String) -> Void
    public var standardError: @Sendable (String) -> Void
    /// Test hook at the export's cooperative cancellation points.
    var boundary: @Sendable (UUID, ExportBoundary) throws -> Void = { _, _ in }

    public init(environment: [String: String] = ProcessInfo.processInfo.environment, today: Date = Date(),
                currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
                standardOutput: @escaping @Sendable (String) -> Void,
                standardError: @escaping @Sendable (String) -> Void) {
        self.environment = environment
        self.today = today
        self.currentDirectory = currentDirectory
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    public func run(_ arguments: [String]) async -> CommandStatus {
        do {
            let parsed = try ArgumentParser.parse(arguments)
            if parsed.help { standardOutput(Help.text); return .success }
            if parsed.version { standardOutput("pwm \(Help.version)"); return .success }
            if parsed.listPresets {
                try PresetFile.load(environment: environment)?.names.forEach(standardOutput)
                return .success
            }
            let request = try RequestResolver.resolve(parsed, preset: try preset(parsed), today: today)
            return try await Runner(request: request, currentDirectory: currentDirectory, standardOutput: standardOutput,
                                    standardError: standardError, boundary: boundary).run()
        } catch {
            standardError(error.report)
            return error.status
        }
    }

    /// The preset file is read only when a preset is requested, so a missing
    /// or broken file never affects other runs.
    private func preset(_ parsed: ParsedArguments) throws(CommandError) -> Preset? {
        guard let name = parsed.preset, !parsed.stripOnly else { return nil }
        guard let file = try PresetFile.load(environment: environment) else {
            throw .presetFile(path: PresetFile.location(environment: environment), problem: "not found. Create it to use --preset.")
        }
        guard let preset = file.presets[name] else { throw .unknownPreset(name) }
        return preset
    }
}
