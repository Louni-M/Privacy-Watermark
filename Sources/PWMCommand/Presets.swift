import Foundation
import WatermarkCore

/// The user's preset file. It is only ever read: pwm never creates or rewrites it.
public struct PresetFile: Sendable {
    public let path: String
    public let presets: [String: Preset]

    /// `$XDG_CONFIG_HOME/pwm/presets.json`, or `~/.config/pwm/presets.json`.
    public static func location(environment: [String: String]) -> String {
        if let config = environment["XDG_CONFIG_HOME"], config.hasPrefix("/") {
            return (config as NSString).appendingPathComponent("pwm/presets.json")
        }
        let home = environment["HOME"].flatMap { $0.isEmpty ? nil : $0 } ?? NSHomeDirectory()
        return (home as NSString).appendingPathComponent(".config/pwm/presets.json")
    }

    /// Returns nil when the file does not exist; any other problem is a configuration error.
    public static func load(environment: [String: String]) throws(CommandError) -> PresetFile? {
        let path = location(environment: environment)
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let data: Data
        do { data = try Data(contentsOf: URL(fileURLWithPath: path)) }
        catch { throw .presetFile(path: path, problem: "cannot be read.") }
        return try PresetFile(path: path, data: data)
    }

    init(path: String, data: Data) throws(CommandError) {
        self.path = path
        let root: Any
        do { root = try JSONSerialization.jsonObject(with: data) }
        catch {
            let detail = (error as NSError).userInfo["NSDebugDescription"] as? String ?? "not valid JSON."
            throw .presetFile(path: path, problem: "not valid JSON: \(detail)")
        }
        guard let object = root as? [String: Any], let entries = object["presets"] as? [String: Any] else {
            throw .presetFile(path: path, problem: "expected an object with a \"presets\" object.")
        }
        var presets: [String: Preset] = [:]
        for (name, entry) in entries {
            guard let fields = entry as? [String: Any] else {
                throw .presetFile(path: path, problem: "preset \"\(name)\" must be an object.")
            }
            presets[name] = try Self.preset(fields, name: name, path: path)
        }
        self.presets = presets
    }

    public var names: [String] { presets.keys.sorted() }

    public static let keys = ["text", "date", "opacity", "size", "spacing", "color", "direction", "format", "pdf-mode", "dpi"]

    /// Same ranges and spellings as the command-line options, so a preset can
    /// never hold a value the parser would reject.
    private static func preset(_ fields: [String: Any], name: String, path: String) throws(CommandError) -> Preset {
        func problem(_ text: String) -> CommandError { .presetFile(path: path, problem: "preset \"\(name)\": \(text)") }
        if let unknown = fields.keys.sorted().first(where: { !keys.contains($0) }) {
            throw problem("unknown setting \"\(unknown)\". Known settings: \(keys.joined(separator: ", ")).")
        }
        func string(_ key: String) throws(CommandError) -> String? {
            guard let value = fields[key] else { return nil }
            guard let text = value as? String else { throw problem("\(key) must be a string.") }
            return text
        }
        func number(_ key: String, _ range: ClosedRange<Double>) throws(CommandError) -> Double? {
            guard let value = fields[key] else { return nil }
            guard let number = value as? NSNumber, !isBoolean(number), number.doubleValue.isFinite,
                  range.contains(number.doubleValue)
            else { throw problem("\(key) must be a number from \(Int(range.lowerBound)) to \(Int(range.upperBound)).") }
            return number.doubleValue
        }
        func choice<T>(_ key: String, _ parse: (String, String) throws(CommandError) -> T) throws(CommandError) -> T? {
            guard let value = try string(key) else { return nil }
            do { return try parse(value, key) }
            catch { if case .invalidValue(_, _, let expected) = error { throw problem("\(key) must be \(expected).") }; throw error }
        }

        var preset = Preset()
        preset.text = try string("text")
        if let text = preset.text {
            do { _ = try WatermarkTextInput.resolve(text, date: false, today: Date()) }
            catch { throw problem("text is longer than \(WatermarkText.limit) characters.") }
        }
        if let value = fields["date"] {
            guard let flag = value as? NSNumber, isBoolean(flag) else { throw problem("date must be true or false.") }
            preset.date = flag.boolValue
        }
        preset.opacity = try number("opacity", 0...100)
        preset.size = try number("size", 12...72)
        preset.spacing = try number("spacing", 50...300)
        preset.color = try choice("color", ArgumentValues.color)
        preset.direction = try choice("direction", ArgumentValues.direction)
        preset.policy = try choice("format", ArgumentValues.policy)
        preset.flattened = try choice("pdf-mode", ArgumentValues.flattened)
        if let value = fields["dpi"] {
            guard let number = value as? NSNumber, !isBoolean(number), [300, 450, 600].contains(number.doubleValue)
            else { throw problem("dpi must be 300, 450 or 600.") }
            preset.dpi = number.intValue
        }
        return preset
    }

    private static func isBoolean(_ number: NSNumber) -> Bool {
        CFGetTypeID(number) == CFBooleanGetTypeID()
    }
}
