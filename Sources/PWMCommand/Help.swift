import Foundation

public enum Help {
    /// The enclosing app's version when installed in Privacy Watermark.app (also through a symlink); `dev` otherwise.
    public static var version: String {
        let key = "CFBundleShortVersionString"
        // X.app/Contents/MacOS/pwm, with symlinks resolved so a link in ~/.local/bin finds its app.
        let app = Bundle.main.executableURL?.resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let bundle = app.flatMap { $0.pathExtension == "app" ? Bundle(url: $0) : nil }
        return bundle?.object(forInfoDictionaryKey: key) as? String
            ?? Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "dev"
    }

    public static var text: String {
        let rows = OptionSpec.all.map { spec -> (String, String) in
            let names = (spec.short.map { "-\($0), " } ?? "    ") + "--" + spec.name + (spec.value.map { " \($0)" } ?? "")
            let summary = spec.summary + (spec.defaultValue.map { " Default: \($0)." } ?? "")
            return (names, summary)
        }
        let width = rows.map(\.0.count).max() ?? 0
        let options = rows.map { "  " + $0.0.padding(toLength: width, withPad: " ", startingAt: 0) + "  " + $0.1 }
        return """
        pwm — watermark images and PDFs with Privacy Watermark, without opening the app.

        Usage:
          pwm TEXT FILE... [options]
          pwm --text TEXT FILE... [options]
          pwm --preset NAME FILE... [options]
          pwm --strip-only FILE... [--out DIR]

        Accepts JPG, JPEG, PNG and PDF files: at most 100 MB each, 50 PDF pages and 20,000 pixels per image side.
        Copies are named NAME_watermarked.EXT (or NAME_stripped.EXT), with " (2)", " (3)"... when a name is taken.
        A PDF exported as JPG or PNG gives a NAME_watermarked folder of NAME_page_001 images.
        Originals and existing files are never modified or replaced.

        Options:
        \(options.joined(separator: "\n"))

        Presets are read from $XDG_CONFIG_HOME/pwm/presets.json, or ~/.config/pwm/presets.json.

        Output:
          Paths of saved copies are printed on standard output, one per line.
          Errors and the summary (saved · failed · excluded · not processed) go to standard error.

        Exit status:
          0    every file was saved
          1    some files were saved, others failed, were excluded or not processed
          2    no file was saved
          64   invalid command line
          78   invalid preset file
          130  interrupted
        """
    }
}
