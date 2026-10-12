import Foundation
import Testing
@testable import PWMCommand

struct HelpTests {
    func run(_ arguments: [String]) async -> (CommandStatus, String, String) {
        let out = Lines(), err = Lines()
        let command = Command(environment: [:], standardOutput: out.append, standardError: err.append)
        let status = await command.run(arguments)
        return (status, out.text, err.text)
    }

    @Test func helpListsEveryOptionWithValuesAndDefaults() async {
        for flag in ["--help", "-h"] {
            let (status, output, errors) = await run([flag])
            #expect(status == .success && errors.isEmpty)
            for spec in OptionSpec.all {
                #expect(output.contains("--" + spec.name), "missing --\(spec.name)")
                if let value = spec.value { #expect(output.contains("--\(spec.name) \(value)")) }
                if let value = spec.defaultValue { #expect(output.contains("Default: \(value).")) }
            }
            for code in ["0 ", "1 ", "2 ", "64 ", "78 ", "130 "] { #expect(output.contains("  " + code)) }
        }
    }

    @Test func helpAndVersionTouchNoFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("a.jpg")
        try Data("not an image".utf8).write(to: source)
        for arguments in [["COPY", source.path, "--help"], ["--version", "COPY", source.path]] {
            let (status, _, errors) = await run(arguments)
            #expect(status == .success && errors.isEmpty)
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["a.jpg"])
        }
        let (_, version, _) = await run(["--version"])
        #expect(version == "pwm \(Help.version)")
    }

    @Test func usageErrorsGoToStandardErrorWithStatus64() async {
        let (status, output, errors) = await run(["COPY", "a.jpg", "--opacity", "150"])
        #expect(status == .usage && output.isEmpty)
        #expect(errors.contains("--opacity") && errors.contains("0 to 100") && errors.contains("--help"))
    }
}
