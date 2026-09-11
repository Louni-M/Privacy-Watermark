import Foundation

public enum WatermarkText {
    public static let limit = 200

    public static func accepted(_ text: String) -> String {
        String(text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n").prefix(limit))
    }

    public static func dateLine(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    public static func containsDateLine(_ line: String, in text: String) -> Bool {
        text.components(separatedBy: "\n").contains(line)
    }

    public static func settingDateLine(_ line: String, included: Bool, in text: String) -> String {
        let text = accepted(text)
        var lines = text.components(separatedBy: "\n")
        if included {
            guard !lines.contains(line) else { return text }
            guard !text.isEmpty else { return line }
            return String(text.prefix(limit - line.count - 1)) + "\n" + line
        }
        guard let index = lines.lastIndex(of: line) else { return text }
        lines.remove(at: index)
        return lines.joined(separator: "\n")
    }
}
