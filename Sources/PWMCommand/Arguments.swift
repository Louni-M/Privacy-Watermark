import Foundation
import WatermarkCore

/// Exit statuses are part of the command's documented contract.
public enum CommandStatus: Int32, Sendable {
    case success = 0, partial = 1, nothingSaved = 2, usage = 64, configuration = 78, interrupted = 130
}

public enum CommandError: Error, Equatable, Sendable {
    case unknownOption(String)
    case missingValue(String)
    case invalidValue(option: String, value: String, expected: String)
    case missingText
    case missingFiles
    case textTooLong(Int)
    case notWithStripOnly(String)
    case unknownPreset(String)
    case presetFile(path: String, problem: String)
    case outputDirectory(String)

    public var message: String {
        switch self {
        case .unknownOption(let option): "Unknown option \(option)."
        case .missingValue(let option): "\(option) needs a value."
        case .invalidValue(let option, let value, let expected): "Invalid value \"\(value)\" for \(option). Expected \(expected)."
        case .missingText: "Missing watermark text. Give it first, or use --text or a preset that defines text."
        case .missingFiles: "No input file given."
        case .textTooLong(let count): "Watermark text is \(count) characters, including any date line. The maximum is \(WatermarkText.limit)."
        case .notWithStripOnly(let option): "\(option) cannot be combined with --strip-only."
        case .unknownPreset(let name): "No preset named \"\(name)\". Use --list-presets to see available presets."
        case .presetFile(let path, let problem): "Preset file \(path): \(problem)"
        case .outputDirectory(let path): "Output folder \(path) does not exist or is not writable."
        }
    }

    public var status: CommandStatus {
        if case .presetFile = self { return .configuration }
        return .usage
    }

    /// Usage errors end with a pointer to the help text.
    public var report: String {
        status == .usage ? "pwm: \(message)\nRun pwm --help for usage." : "pwm: \(message)"
    }
}

/// Values exactly as given on the command line; nil means "not given".
public struct ParsedArguments: Equatable, Sendable {
    public var positionals: [String] = []
    public var help = false
    public var version = false
    public var listPresets = false
    public var stripOnly = false
    public var text: String?
    public var date: Bool?
    public var preset: String?
    public var out: String?
    public var opacity: Double?
    public var size: Double?
    public var spacing: Double?
    public var color: WatermarkColor?
    public var direction: WatermarkDirection?
    public var policy: OutputPolicy?
    public var flattened: Bool?
    public var dpi: Int?
    /// Options given explicitly, by long name, for --strip-only conflicts.
    public var given: [String] = []
    public init() {}
}

/// One table drives both parsing and --help, so they cannot drift apart.
public struct OptionSpec: Sendable {
    public let name: String
    public let short: String?
    public let value: String?
    public let summary: String
    public let defaultValue: String?

    public static let all: [OptionSpec] = [
        .init(name: "text", short: nil, value: "TEXT", summary: "Watermark text, instead of the first argument. \\n starts a new line.", defaultValue: nil),
        .init(name: "date", short: nil, value: nil, summary: "Add today's date as a DD-MM-YYYY line.", defaultValue: "off"),
        .init(name: "no-date", short: nil, value: nil, summary: "Do not add the date, even if the preset does.", defaultValue: nil),
        .init(name: "opacity", short: nil, value: "0-100", summary: "Watermark opacity in percent.", defaultValue: "30"),
        .init(name: "size", short: nil, value: "12-72", summary: "Text size, relative to an A4 page.", defaultValue: "36"),
        .init(name: "spacing", short: nil, value: "50-300", summary: "Minimum spacing between repetitions.", defaultValue: "150"),
        .init(name: "color", short: nil, value: "white|black|gray", summary: "Watermark color.", defaultValue: "black"),
        .init(name: "direction", short: nil, value: "up|down", summary: "Diagonal direction.", defaultValue: "up"),
        .init(name: "format", short: nil, value: "keep|pdf|jpg|png", summary: "Output format. keep: PDF→PDF, PNG→PNG, JPG→JPG.", defaultValue: "keep"),
        .init(name: "pdf-mode", short: nil, value: "flattened|text", summary: "PDF output: flattened image pages, or selectable text.", defaultValue: "flattened"),
        .init(name: "dpi", short: nil, value: "300|450|600", summary: "Flattened PDF quality.", defaultValue: "450"),
        .init(name: "out", short: "o", value: "DIR", summary: "Existing folder for all copies.", defaultValue: "beside each source"),
        .init(name: "preset", short: nil, value: "NAME", summary: "Load text and settings from the preset file.", defaultValue: nil),
        .init(name: "list-presets", short: nil, value: nil, summary: "Print available preset names.", defaultValue: nil),
        .init(name: "strip-only", short: nil, value: nil, summary: "Copy JPG/PNG images without EXIF/GPS metadata and without a watermark.", defaultValue: nil),
        .init(name: "help", short: "h", value: nil, summary: "Show this help.", defaultValue: nil),
        .init(name: "version", short: nil, value: nil, summary: "Show the version.", defaultValue: nil)
    ]

    static func named(_ argument: String) -> OptionSpec? {
        if argument.hasPrefix("--") { return all.first { "--" + $0.name == argument } }
        return all.first { $0.short.map { "-" + $0 } == argument }
    }
}

public enum ArgumentParser {
    public static func parse(_ arguments: [String]) throws(CommandError) -> ParsedArguments {
        var result = ParsedArguments()
        var index = 0
        var optionsEnded = false
        while index < arguments.count {
            let argument = arguments[index]
            index += 1
            guard !optionsEnded, argument.hasPrefix("-"), argument != "-" else {
                result.positionals.append(argument)
                continue
            }
            if argument == "--" { optionsEnded = true; continue }
            var name = argument
            var inline: String?
            if argument.hasPrefix("--"), let equals = argument.firstIndex(of: "=") {
                name = String(argument[..<equals])
                inline = String(argument[argument.index(after: equals)...])
            }
            guard let spec = OptionSpec.named(name) else { throw .unknownOption(name) }
            let option = "--" + spec.name
            var value: String?
            if spec.value != nil {
                if let inline { value = inline }
                else if index < arguments.count { value = arguments[index]; index += 1 }
                else { throw .missingValue(option) }
            } else if inline != nil {
                throw .invalidValue(option: option, value: inline!, expected: "no value")
            }
            try apply(spec.name, value: value, to: &result)
            result.given.append(spec.name)
        }
        return result
    }

    private static func apply(_ name: String, value: String?, to result: inout ParsedArguments) throws(CommandError) {
        let option = "--" + name
        let value = value ?? ""
        switch name {
        case "text": result.text = value
        case "date": result.date = true
        case "no-date": result.date = false
        case "opacity": result.opacity = try number(value, option: option, range: 0...100)
        case "size": result.size = try number(value, option: option, range: 12...72)
        case "spacing": result.spacing = try number(value, option: option, range: 50...300)
        case "color": result.color = try ArgumentValues.color(value, option: option)
        case "direction": result.direction = try ArgumentValues.direction(value, option: option)
        case "format": result.policy = try ArgumentValues.policy(value, option: option)
        case "pdf-mode": result.flattened = try ArgumentValues.flattened(value, option: option)
        case "dpi": result.dpi = try ArgumentValues.dpi(value, option: option)
        case "out": result.out = value
        case "preset": result.preset = value
        case "list-presets": result.listPresets = true
        case "strip-only": result.stripOnly = true
        case "help": result.help = true
        case "version": result.version = true
        default: throw .unknownOption(option)
        }
    }

    static func number(_ value: String, option: String, range: ClosedRange<Double>) throws(CommandError) -> Double {
        let expected = "a number from \(Int(range.lowerBound)) to \(Int(range.upperBound))"
        guard let number = Double(value.trimmingCharacters(in: .whitespaces)), number.isFinite, range.contains(number)
        else { throw .invalidValue(option: option, value: value, expected: expected) }
        return number
    }
}

/// Shared by the parser and the preset file, so both accept the same spellings.
enum ArgumentValues {
    static func color(_ value: String, option: String) throws(CommandError) -> WatermarkColor {
        switch value.lowercased() {
        case "white": .white
        case "black": .black
        case "gray", "grey": .gray
        default: throw .invalidValue(option: option, value: value, expected: "white, black or gray")
        }
    }

    static func direction(_ value: String, option: String) throws(CommandError) -> WatermarkDirection {
        switch value.lowercased() {
        case "up": .ascending
        case "down": .descending
        default: throw .invalidValue(option: option, value: value, expected: "up or down")
        }
    }

    static func policy(_ value: String, option: String) throws(CommandError) -> OutputPolicy {
        switch value.lowercased() {
        case "keep": .original
        case "pdf": .pdf
        case "jpg", "jpeg": .jpg
        case "png": .png
        default: throw .invalidValue(option: option, value: value, expected: "keep, pdf, jpg or png")
        }
    }

    static func flattened(_ value: String, option: String) throws(CommandError) -> Bool {
        switch value.lowercased() {
        case "flattened": true
        case "text": false
        default: throw .invalidValue(option: option, value: value, expected: "flattened or text")
        }
    }

    static func dpi(_ value: String, option: String) throws(CommandError) -> Int {
        guard let dpi = Int(value), [300, 450, 600].contains(dpi)
        else { throw .invalidValue(option: option, value: value, expected: "300, 450 or 600") }
        return dpi
    }
}
