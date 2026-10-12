import Foundation
import PWMCommand

let command = Command(
    standardOutput: { FileHandle.standardOutput.write(Data(($0 + "\n").utf8)) },
    standardError: { FileHandle.standardError.write(Data(($0 + "\n").utf8)) })
let run = Task { await command.run(Array(CommandLine.arguments.dropFirst())) }

// Control-C cancels cooperatively: the current input stops at its next page
// boundary, its staging folder is removed, and the summary is still printed.
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
interrupt.setEventHandler { run.cancel() }
interrupt.resume()

let status = await run.value
exit(status.rawValue)
