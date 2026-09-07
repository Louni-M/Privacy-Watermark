import AppKit
import Foundation

let bundle = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let process = Process()
process.executableURL = bundle.appendingPathComponent("Contents/MacOS/PassportFiligrane")
process.standardOutput = FileHandle.nullDevice
process.standardError = FileHandle.nullDevice
try process.run()
defer { if process.isRunning { process.terminate() } }
let deadline = Date().addingTimeInterval(15)
var visible = false
while process.isRunning && Date() < deadline {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    visible = windows.contains {
        guard $0[kCGWindowOwnerPID as String] as? Int32 == process.processIdentifier,
              let bounds = $0[kCGWindowBounds as String] as? [String: Double] else { return false }
        return (bounds["Width"] ?? 0) >= 300 && (bounds["Height"] ?? 0) >= 200
    }
    if visible { break }
    Thread.sleep(forTimeInterval: 0.02)
}
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let report: [String: Any] = ["passed": visible, "check": "Built universal app launches and displays a window", "os": ProcessInfo.processInfo.operatingSystemVersionString]
try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("bundle-launch.json"))
if !visible { throw NSError(domain: "BundleLaunch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Built app did not display a window"]) }
