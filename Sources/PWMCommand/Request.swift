import Foundation
import WatermarkCore

/// Saved text and settings; every field is optional and falls back to the app default.
public struct Preset: Equatable, Sendable {
    public var text: String?
    public var date: Bool?
    public var opacity: Double?
    public var size: Double?
    public var spacing: Double?
    public var color: WatermarkColor?
    public var direction: WatermarkDirection?
    public var policy: OutputPolicy?
    public var flattened: Bool?
    public var dpi: Int?
    public init() {}
}

/// Everything needed to run an export, already validated.
public struct ExportRequest: Equatable, Sendable {
    public var files: [String]
    public var watermark: WatermarkSettings
    public var policy: OutputPolicy
    public var settings: ExportSettings
    public var out: String?
    public var stripOnly: Bool
    public var suffix: String { stripOnly ? "_stripped" : "_watermarked" }
}

public enum WatermarkTextInput {
    /// Expands the typed two-character `\n`, normalizes line breaks like the app,
    /// and adds the date line. Over-long text is rejected, never shortened.
    public static func resolve(_ text: String, date: Bool, today: Date, timeZone: TimeZone = .current) throws(CommandError) -> String {
        var result = text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if date {
            let line = WatermarkText.dateLine(for: today, timeZone: timeZone)
            if !WatermarkText.containsDateLine(line, in: result) {
                result = result.isEmpty ? line : result + "\n" + line
            }
        }
        guard result.count <= WatermarkText.limit else { throw .textTooLong(result.count) }
        return result
    }
}

public enum RequestResolver {
    static let stripConflicts = ["text", "date", "no-date", "opacity", "size", "spacing", "color", "direction",
                                 "format", "pdf-mode", "dpi", "preset"]

    /// Precedence: explicit option > preset > app default.
    public static func resolve(_ parsed: ParsedArguments, preset: Preset?, today: Date,
                               timeZone: TimeZone = .current) throws(CommandError) -> ExportRequest {
        if parsed.stripOnly {
            if let conflict = parsed.given.first(where: stripConflicts.contains) { throw .notWithStripOnly("--" + conflict) }
            guard !parsed.positionals.isEmpty else { throw .missingFiles }
            var watermark = WatermarkSettings()
            watermark.text = ""
            return ExportRequest(files: parsed.positionals, watermark: watermark, policy: .original,
                                 settings: ExportSettings(), out: parsed.out, stripOnly: true)
        }
        var files = parsed.positionals
        let text: String
        if let explicit = parsed.text ?? preset?.text {
            text = explicit
        } else {
            guard !files.isEmpty else { throw .missingText }
            text = files.removeFirst()
        }
        guard !files.isEmpty else { throw .missingFiles }

        var watermark = WatermarkSettings()
        watermark.text = try WatermarkTextInput.resolve(text, date: parsed.date ?? preset?.date ?? false,
                                                        today: today, timeZone: timeZone)
        if let value = parsed.opacity ?? preset?.opacity { watermark.opacity = value }
        if let value = parsed.size ?? preset?.size { watermark.size = value }
        if let value = parsed.spacing ?? preset?.spacing { watermark.spacing = value }
        if let value = parsed.color ?? preset?.color { watermark.color = value }
        if let value = parsed.direction ?? preset?.direction { watermark.direction = value }
        var settings = ExportSettings()
        if let value = parsed.flattened ?? preset?.flattened { settings.flattened = value }
        if let value = parsed.dpi ?? preset?.dpi { settings.dpi = value }
        return ExportRequest(files: files, watermark: watermark, policy: parsed.policy ?? preset?.policy ?? .original,
                             settings: settings, out: parsed.out, stripOnly: false)
    }
}
