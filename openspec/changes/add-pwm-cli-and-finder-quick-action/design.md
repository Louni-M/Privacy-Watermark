## Context

See proposal.md for motivation and the specs for required behavior. Constraints that shape the approach:

- `WatermarkCore` already owns validation (`SourceValidation`, `SourceDocument.load`), rendering, encoding with metadata removal (`Renderer.encoded`, `ImageMetadata`), naming (`DestinationAllocator`), atomic publication (`BatchExport.save`) and outcome accounting (`BatchExport.run`, `BatchRunResult`).
- `BatchExport.run` writes every item into one destination directory, and `DestinationAllocator` hard-codes the `_watermarked` suffix. The CLI needs a destination beside each source, and `--strip-only` needs a `_stripped` suffix.
- The project has no third-party dependencies, and the README states this. The app is a SwiftPM package built by `scripts/build-app.sh` into an ad-hoc signed universal bundle; there is no Xcode project.
- Tests run with Swift Testing through `scripts/test.sh`. Executable targets with `main.swift` are awkward to import from tests.
- Automator and Shortcuts run shell scripts with a minimal environment: no login `PATH`, and often the `C` locale.

## Goals / Non-Goals

**Goals:**
- One implementation of export behavior, shared by the app and `pwm`. The CLI adds only parsing, presets and terminal reporting.
- A Quick Action that is a thin, inspectable shell layer over `pwm`, installable without Xcode, signing credentials or administrator rights.
- Keep the app's behavior, UI and existing tests unchanged.

**Non-Goals:**
- No in-app UI for installing the Quick Action in this change.
- No parallel processing. Export stays sequential, as in the app, to bound memory.
- No change to the DMG layout. `pwm` simply travels inside the app bundle.

## Decisions

### 1. Package layout: `PWMCommand` library + thin `pwm` executable
Add a `PWMCommand` target (`Sources/PWMCommand/`) containing the argument parser, preset loading, invocation model and runner. Its output and exit code are injectable, which makes it testable. A `pwm` executable target (`Sources/pwm/main.swift`) only wires `CommandLine.arguments`, the environment, the standard streams, SIGINT and `exit()`. A new `PWMCommandTests` target tests the library directly, plus a few end-to-end runs of the built binary on fixtures.
- *Alternative:* everything in the executable target, tested with `@testable import`. Rejected because `main.swift` top-level code complicates test linking under SwiftPM.

### 2. Generalize core export instead of re-implementing it
- `DestinationAllocator` gains a `suffix` parameter (default `"_watermarked"`).
- `BatchExport.run` gains an overload taking `destination: (BatchItem) -> URL` and a suffix. It keeps one allocator per destination directory, each protecting **all** run sources. The existing signature forwards to it with a constant directory, so app behavior and tests are unchanged.
- The CLI builds `BatchItem`s, validates them with `SourceValidation.inspect` (the same path the app uses), deduplicates by `FileIdentity`, then calls `run`. Outcome counting therefore stays in `BatchRunResult`, and the saved + failed + excluded + not processed invariant holds by construction. Missing paths and directories become items that fail validation, so they count as excluded.
- *Alternative:* a separate CLI loop around `BatchExport.save`. Rejected because it would duplicate the outcome accounting, which is the subtle part.

### 3. Hand-written parser
The parser has a small table of option specs (name, short alias, value kind, allowed range or values) and a single pass over the arguments. It supports `--opt value`, `--opt=value`, `--`, and interleaved positionals. Errors are typed (`unknownOption`, `missingValue`, `invalidValue(range)`, …) and map to messages and exit code 64. The help text is generated from the same table, so `--help` cannot drift from the parser.
- *Alternative:* `swift-argument-parser`. Rejected by the maintainer to keep the project free of third-party dependencies.

### 4. Settings mapping and text
- `--direction up|down` maps to `WatermarkDirection.ascending|descending`; `--color` maps to the three existing `WatermarkColor` cases. The app has no free color choice, so there is no hex option.
- `--format keep` uses `OutputPolicy.original`. `--pdf-mode text` sets `flattened = false`.
- The date line uses `WatermarkText.dateLine` and `settingDateLine`. Text is normalized with the app's line-break rules, and the literal `\n` is expanded so line breaks can be typed easily in shells and dialogs.
- Unlike the app's editor, which shortens text while typing, the CLI rejects text over 200 characters. A script must not silently change the watermark it asked for.

### 5. Presets
Presets are a JSON object `{ "presets": { "<name>": { "text": "…", "date": true, "opacity": 40, … } } }`, decoded with `Codable` into optional fields. All fields are validated with the same ranges as the parser. The file is read only. Its location follows `XDG_CONFIG_HOME`, so tests can point it to a temporary directory.

### 6. `--strip-only` reuses the image export path
A strip-only run is an export with empty watermark text, the source's own image format and the `_stripped` suffix. The renderer already draws nothing for blank text, and `Renderer.encoded` already writes no source metadata and runs `ImageMetadata.removingAncillaryMetadata`. PDFs are excluded before export.
- *Alternative:* a lossless byte-level strip of the source JPEG/PNG segments. It avoids a JPEG generation loss, but it is a second code path for a privacy guarantee, and it would drop the EXIF orientation tag without applying it. Rejected for now. The single re-encode at quality 0.9 matches what watermarked image exports already do.

### 7. Cancellation and streams
`main.swift` installs a `DispatchSource` SIGINT handler that cancels the export `Task`. `BatchExport`'s existing cooperative boundaries clean up staging. The runner then reports the not-processed count and exits with code 130. stdout receives only output paths, so callers such as the Quick Action can collect them. Everything else goes to stderr, and nothing is written to disk except the outputs.

### 8. Quick Action: Automator service bundle generated by an install script
- `scripts/quick-action/` contains:
  - a template `Watermark.workflow` (`Contents/Info.plist` with an `NSServices` entry for `public.jpeg`, `public.png` and `com.adobe.pdf` in Finder, plus `Contents/document.wflow` with one **Run Shell Script** action that passes input as arguments);
  - the actual logic in `watermark.zsh`;
  - `install.sh` and `uninstall.sh`.
- The inline Automator script is a two-line launcher. It sets `LC_ALL=en_US.UTF-8` and `LANG`, then `exec`s `watermark.zsh` from the workflow's own `Contents/Resources`. All logic therefore lives in a versioned, lintable file rather than inside the plist.
- `watermark.zsh` does the following:
  - resolves `pwm` as described in the spec, with the installed path written by `install.sh` into `Contents/Resources/pwm-path`;
  - shows `choose from list` when presets exist, then `display dialog` with the buttons Cancel / Without date / With date (default). Text is passed to and from `osascript` through `argv` or stdin, never interpolated into AppleScript source;
  - runs `pwm` without `--out`, captures stdout paths and stderr;
  - posts `display notification` on full success. Otherwise it shows `display alert` with the reasons and an optional **Reveal in Finder**, which calls `open -R` or Finder `reveal` with the saved paths.
- `install.sh` copies the template to `~/Library/Services/Watermark.workflow`, replacing only that bundle. It records the `pwm` path, optionally runs `ln -s` into `~/.local/bin` with `--link`, and refreshes services with `/System/Library/CoreServices/pbs -update`. The scripts are also embedded in the app at `Contents/Resources/quick-action/`, so DMG users can run them from the installed app.
- *Alternative:* a Shortcuts `.shortcut` file. Rejected because shared shortcuts must be signed and imported interactively, which cannot be scripted or diffed. App Intents and Finder extensions are later options (see proposal Non-goals).

### 9. Bundling and verification
`build-app.sh` builds `pwm` for both architectures, runs `lipo` into `Contents/MacOS/pwm`, and copies the Quick Action scripts into `Contents/Resources/quick-action/`. It signs `pwm` ad hoc **before** signing the app, so the nested code is sealed. It then verifies the slices, runs `codesign --verify --strict`, and checks that `pwm --version` matches `CFBundleShortVersionString`. `pwm` reads its version from `Bundle.main`, which resolves to the enclosing app, and falls back to `dev` under `swift run`. `verify-dmg.sh` gets the same `pwm` checks.

## Risks / Trade-offs

- [The hand-written `document.wflow` format is undocumented and may change between macOS versions] → Keep the template minimal and the logic outside it. Manual acceptance on macOS 14 and the current macOS: install, Finder menu, run, uninstall. Uninstall is a plain bundle removal.
- [Quick Action dialogs and notifications are attributed to Automator or Script Editor, and the first run may ask for automation or notification permission] → Document the expected one-time prompts. Full-success feedback is a notification, not a modal, so a denied notification permission loses no data.
- [An ad-hoc signed `pwm` inside a downloaded, quarantined app may be blocked when run from the Quick Action before the app has been approved once] → Document that the app must be opened once and approved first. Do not remove quarantine.
- [JPEG re-encoding in `--strip-only` causes a small generation loss] → This is documented. It matches image export, and lossless stripping can be added later behind the same flag.
- [The existing image pipeline does not apply EXIF orientation, so a rotated-camera photo may export sideways, both in the app and with `pwm`] → Out of scope for parity. It is tracked separately and verified with a fixture before release notes promise otherwise.
- [Exit code 1 for partial success may surprise scripts that treat any excluded input as fatal] → The exit codes are documented in `--help` and the README.
- [Beside-source output in read-only folders, such as a mounted DMG or a shared volume] → Fails per input with the app's write-failure message. `--out` is the documented workaround.

## Migration Plan

The change is purely additive. Existing app users see no difference until they run the install script. Rollback: run `uninstall.sh`, or delete `~/Library/Services/Watermark.workflow` and the `~/.local/bin/pwm` link. Reverting the package change removes `pwm` from future builds.

## Open Questions

- Should a later change add an app menu item (**Install Finder Quick Action…**) so DMG users never need Terminal? This does not affect this change's specs or tasks.
