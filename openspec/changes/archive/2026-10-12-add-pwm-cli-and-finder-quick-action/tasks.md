# Tasks

## 1. Generalize core export

- [x] 1.1 Add a `suffix` parameter to `DestinationAllocator` (default `"_watermarked"`) and verify that new `WatermarkCoreTests` cover `_stripped` names, ` (2)` suffixes and page-series folders, and that existing naming tests pass unchanged.
- [x] 1.2 Add a `BatchExport.run` overload taking a per-item destination closure and a suffix, with one allocator per directory that protects all run sources. Make the existing signature forward to it. Verify with tests that sources in two folders each get a copy beside them, that saved + failed + excluded + not processed equals the source count, and that `scripts/test.sh` passes with no app test changes.

## 2. Argument parsing and help

- [x] 2.1 Add the `PWMCommand` library, the `pwm` executable and the `PWMCommandTests` targets to `Package.swift`. Verify that `swift build` produces `pwm` and an empty test runs through `scripts/test.sh`.
- [x] 2.2 Implement the table-driven parser covering TEXT, files, `--opt value`, `--opt=value`, `--` and interleaved positionals. It maps to `WatermarkSettings`, `ExportSettings` and `OutputPolicy` with the app's defaults and ranges. Verify with tests for defaults, every option, every invalid value, unknown option, missing value, missing TEXT or files, and dash-prefixed paths after `--`.
- [x] 2.3 Implement the text rules: expand `\n`, normalize line breaks, add the `--date` line through `WatermarkText`, and reject text over 200 characters with the actual length. Verify with tests for a fixed date, accented text, and the over-limit case with and without `--date`.
- [x] 2.4 Generate `--help` from the option table and implement `--version`, with `Bundle.main` and a `dev` fallback. Verify with a test that every parser option appears in the help with its values and default, and that both flags exit 0 without touching files.

## 3. Presets

- [x] 3.1 Implement read-only preset loading from `$XDG_CONFIG_HOME/pwm/presets.json` or `~/.config/pwm/presets.json`, with range validation, precedence (explicit options including `--text`/`--date`/`--no-date` > preset > default), optional TEXT when the preset defines one, and `--list-presets`. Verify with tests using a temporary `XDG_CONFIG_HOME`: use and override, unknown name (64), malformed JSON and out-of-range value (78, file named), missing file only failing when a preset is requested, and the file left unmodified.

## 4. Running exports from the command line

- [x] 4.1 Implement the runner. It builds and deduplicates `BatchItem`s by `FileIdentity`, validates them with `SourceValidation.inspect`, checks that `--out` exists and is writable, and runs export beside each source or into `--out`. Verify with fixture tests for beside-source output, `--out`, an existing name giving ` (2)`, PDF to page-image folder, a symbolic-link duplicate, and originals unchanged by hash.
- [x] 4.2 Implement reporting: output paths on stdout only; per-file reasons and the `saved · failed · excluded · not processed` summary on stderr, without watermark text; exit codes 0, 1, 2, 64, 78 and 130. Verify with tests for all-saved, partial, none-saved, excluded directory or missing path, and an assertion that the watermark text never appears in stderr.
- [x] 4.3 Wire SIGINT in `main.swift` to cancel the export task. Verify with a runner test that cancels at a page boundary (completed copy kept, no staging left, exit 130), and manually with Control-C on a 50-page fixture.
- [x] 4.4 Implement `--strip-only`: empty text, the source's image format, the `_stripped` suffix, and PDFs excluded with a reason. Text, appearance, format, PDF and preset options are rejected. Verify with tests that a GPS/EXIF fixture loses its metadata (checked through ImageIO) while keeping its pixel dimensions, that PDF input exits 2, and that combining options gives a usage error.
- [x] 4.5 Add an end-to-end test that runs the built `pwm` binary on synthetic fixtures with accented text under `LC_ALL=C`. Verify that output paths, exit code and rendered output equal the app's `Processing.export` for the same settings.
- [x] 4.6 Document `pwm` in the README: usage, defaults, exit codes, presets with an example file and a privacy note, and `--strip-only` with its re-encode note. Add the local-processing and no-log statement to `SECURITY.md`. Verify that every documented command example runs as written against fixtures.

## 5. Bundle `pwm` in the app

- [x] 5.1 Update `scripts/build-app.sh` so it builds `pwm` for arm64 and x86_64 and runs `lipo` into `Contents/MacOS/pwm`. It copies `scripts/quick-action/` into `Contents/Resources/quick-action/`, signs `pwm` before the app, and verifies architectures, strict signature and that `pwm --version` equals `CFBundleShortVersionString`. Verify by running the script, and confirm it fails when one `pwm` slice is removed.
- [x] 5.2 Add the same `pwm` checks to `scripts/verify-dmg.sh` and update the release tests in `scripts/test-release.py` if they enumerate bundle contents. Verify that `python3 scripts/test-release.py` passes and that a locally built DMG verifies.

## 6. Finder Quick Action

- [x] 6.1 Create the `scripts/quick-action/Watermark.workflow` template: an `Info.plist` `NSServices` entry for Finder with `public.jpeg`, `public.png` and `com.adobe.pdf`, and a minimal `document.wflow` with a Run Shell Script launcher that sets `LC_ALL` and `LANG` to `en_US.UTF-8` and execs `Contents/Resources/watermark.zsh`. Verify that `plutil -lint` passes on both plists.
- [x] 6.2 Implement `watermark.zsh`:
  - resolve `pwm` from the recorded path, then `/Applications`, then `~/Applications`, with an alert if it is missing;
  - show the preset list when presets exist, then the text dialog (Cancel / Without date / With date by default), passing text through argv or stdin only and re-prompting on the 200-character error;
  - run `pwm`, then show a self-closing confirmation with Reveal in Finder on full success, or an alert with reasons and Reveal in Finder otherwise.

  Verify with `zsh -n`, and with a test harness that stubs `osascript` and `pwm` and covers cancel, a missing `pwm`, partial failure and accented text under `LC_ALL=C`.
- [x] 6.3 Implement `install.sh`, with an optional `--link [DIR]` and a `PATH` hint, and `uninstall.sh`. Neither needs administrator rights or touches quarantine, and uninstall removes only what install created. Then refresh services with `pbs -update`. Verify with a test that installs into a temporary `HOME`, checks the recorded `pwm` path, link, reinstall and uninstall, and confirms no other files changed.
- [x] 6.4 Document Quick Action installation, use, the expected one-time permission prompts, the open-the-app-first approval requirement, and uninstallation in the README. Verify by following the README steps from the built app on this Mac.

## 7. Integration acceptance

- [x] 7.1 Run `swift build`, `scripts/test.sh`, `scripts/build-app.sh` and `scripts/smoke-test.sh`. Verify that all pass and that app behavior and the existing smoke test are unchanged.
- [x] 7.2 Run a manual Finder acceptance on this Mac: install the Quick Action, Control-click 1 and then several synthetic JPG/PNG/PDF files, choose Quick Actions → Watermark, enter accented text with date, and check copies beside the originals with originals unchanged by hash. Cover cancel, partial failure with Reveal in Finder, a preset, and uninstall. Record the results, macOS version and architecture, with personal paths replaced by `<workspace>`, in `docs/cli/acceptance.md`, marking macOS 14 and Intel coverage pending if not performed. Verify that `python3 scripts/check-evidence-privacy.py` passes.
