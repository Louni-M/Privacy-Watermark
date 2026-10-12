## Why

Watermarking a single document today means opening the app, adding the file, typing the text and choosing a destination folder. For the common case of protecting one or a few copies before sharing them, users want to act directly from Finder in a few seconds, without opening the app window. Scripts and automation also have no way to reuse the app's validated, transactional export.

## What Changes

- Add a `pwm` command-line executable to the existing Swift package. It only parses arguments and calls `WatermarkCore`; validation, rendering, naming and transactional output are not duplicated.
- `pwm "TEXT" FILE… [options]` exposes the app's shared settings: today's date line, opacity, size, spacing, color, diagonal direction, output format, PDF mode and DPI. Defaults match the app.
- Without `--out`, copies are written beside each source; with `--out DIR`, into that folder. Naming, ` (2)` suffixes, PDF page-image folders, input limits and never-modified originals follow the app's existing export contract.
- Clear exit codes, a stderr summary using the app's outcome categories (saved / failed / excluded), and a `--help` text.
- Optional named presets read from a user configuration file (`~/.config/pwm/presets.json`), so text and appearance need not be retyped.
- `--strip-only` to remove EXIF/GPS metadata from images without adding a watermark.
- A Finder Quick Action, **Watermark**, for selected JPG/JPEG/PNG/PDF files. It asks for the watermark text in a dialog, with today's date pre-selected, calls `pwm` and writes copies beside the originals. It then confirms completion and can reveal the results in Finder. The Quick Action locates `pwm` without relying on `PATH` and forces a UTF-8 locale, so accented text is not corrupted.
- `scripts/build-app.sh` embeds `pwm` in the universal app bundle. An install script installs the Quick Action in `~/Library/Services` and optionally links `pwm` into a user `bin` directory.
- No third-party dependency: arguments use a small in-house parser rather than `swift-argument-parser`.

## Capabilities

### New Capabilities

- `watermark-cli`: The `pwm` command: arguments and defaults, output placement and naming, validation and limits, presets, metadata-only stripping, exit codes and summary reporting.
- `finder-quick-action`: The Finder **Watermark** Quick Action: file eligibility, text prompt, locating `pwm`, text encoding, completion feedback, and installation and removal.

### Modified Capabilities

- `native-app-delivery`: The universal app bundle also contains a universal `pwm` executable. Documentation covers the CLI and Quick Action installation, without requiring additional runtimes or third-party dependencies.

## Impact

- `Package.swift`: a new `pwm` executable target depending on `WatermarkCore`, plus a CLI test target.
- `WatermarkCore`: possibly small public entry points for headless batch export to a per-source destination and for metadata-only stripping. Existing behavior is unchanged.
- `scripts/build-app.sh` and app verification: embed and verify the `pwm` slices and signature. New Quick Action installation and uninstallation scripts.
- `README.md` and `SECURITY.md`: CLI usage, Quick Action installation, and the privacy of the preset file.
- The app UI, default settings, export results and DMG layout stay the same.

## Non-goals

App Intents and Shortcuts actions, a Finder Sync or Action extension, a watched folder or Google Drive / Google Photos integration, Developer ID signing or notarization, and Homebrew distribution are separate changes.
