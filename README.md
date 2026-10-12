# Privacy Watermark

[![Build & tests](https://github.com/Louni-M/Privacy-Watermark/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Louni-M/Privacy-Watermark/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/Louni-M/Privacy-Watermark?label=release)](https://github.com/Louni-M/Privacy-Watermark/releases/latest)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](#download-for-mac)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-F05138?logo=swift&logoColor=white)](#build-and-install)

A native macOS app for watermarking images and PDFs together before sharing copies. Built with SwiftUI, PDFKit, Core Graphics and ImageIO; all processing stays on your Mac.

Requires **macOS 14 or newer**, on Apple Silicon or Intel.

https://github.com/user-attachments/assets/58cd5805-29fc-4b51-af22-13063b5ddb02

## Download for Mac

**[Download for Mac](https://github.com/Louni-M/Privacy-Watermark/releases/latest/download/Privacy-Watermark.dmg)** · 4.01 MB · [Version 2.1.3](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.1.3)

Install in three steps:

1. Download `Privacy-Watermark.dmg` and double-click it.
2. Drag **Privacy Watermark** onto **Applications** in the installation window.
3. Wait for copying to finish, eject the disk image, and open the app from Applications.

This free release is **ad-hoc signed and not notarized by Apple**. If macOS says Apple could not verify the app is free of malware, click **Done**, then open **System Settings → Privacy & Security → Open Anyway**, then confirm and authenticate if asked. Only approve a download you trust. The approval button is available for about an hour after attempting to open the app. See [installation help](assets/dmg/Install.txt), also included in the DMG, for missing approval controls or other warnings.

## Use

1. Try the interactive **Sample preview**, or choose **Add files** / press **⌘O** to select JPG, JPEG, PNG and PDF files, or drag files into the window. Later additions append to the list; repeated additions of the same file are ignored.
2. Enter shared watermark text (up to 200 characters, including line breaks). Select **Include today’s date** (⇧⌘D) to add an editable `DD-MM-YYYY` line (for example, `09-09-2026`); deselect it to remove that line. Insertion keeps the complete date within 200 characters by shortening the end of existing text when necessary. Expand **Appearance** (⇧⌘A) to adjust opacity, size, spacing, color and diagonal direction for every file. Sliders use black unfilled tracks, blue filled portions and light thumbs; click a slider and use arrow keys for keyboard adjustment. Sliders and editable numbers stay synchronized; size and spacing scale with the document. Spacing is a requested minimum: longer text automatically gets extra room between repetitions, preserving your font size and line breaks. **Reset appearance** (⇧⌘R, while expanded) resets only those five appearance choices.
3. Select a file to inspect it. PDF arrows navigate every page; use zoom and scrolling for details, or **Fit to window** for the whole page.
4. Keep each input's original format, or choose PDF, JPG or PNG for the batch. Review the predicted output files and PDF page-image folders, then choose **Export N documents…** (⇧⌘S) and one destination folder. The button counts eligible source documents; invalid files remain visible and are excluded. Your originals stay unchanged.

Use Control-Tab to leave the multiline editor and Tab to move between numeric fields. Drag the divider to resize the settings panel; scroll it to reach expanded controls in a small window. The export action and its document count stay visible below the scrolling settings, replaced by progress and Cancel during export. Remove individual files or choose **Clear all** to empty the list and return to the sample. The sample never enters the batch or exports. Blank text and 0% opacity are allowed without warnings or extra confirmations. Shared settings survive additions, removals and selection changes; restarting restores defaults and an empty batch. Selecting another file resets page and view to the first page and Fit. Changing PDF page preserves your zoom.

Copies use `<name>_watermarked.ext`, adding ` (2)`, ` (3)` and so on when names are already used. PDFs converted to images get a separate `<name>_watermarked` folder containing numbered `<name>_page_001.jpg` or `.png` files. Inputs are never merged, existing destinations are never replaced, and another export creates new copies. This folder workflow also applies to one file; PNG input defaults to PNG.

Files validate progressively. Invalid files stay visible and do not prevent valid files from exporting once checking finishes. During export, you can browse previews or **Cancel**; collection and shared settings are locked. Cancellation keeps completed copies and removes unfinished output. The summary distinguishes saved documents, failed export attempts, inputs excluded by validation, and documents not processed or interrupted by cancellation. If a queued source changes or becomes unavailable, restore access and remove/add it again to review its current content.

After an export saves files, **Reveal in Finder** appears below the export summary at the bottom of the preview pane. It selects the saved copies in Finder, including completed outputs from a cancelled or partially failed export.

| Input | Output |
|---|---|
| JPG / PNG | JPG, PNG, or single-page PDF |
| PDF | PDF, or one JPG / PNG file per page |

PDF export defaults to **Flattened at 450 DPI**, with 300 and 600 DPI available. **Selectable text** mode preserves source text and adds a separate vector watermark. PDF mode and quality controls appear only for eligible PDF-to-PDF outputs; quality appears only in Flattened mode. PDF page images retain the existing 72-DPI output sizing, stated explicitly when JPG or PNG is selected.

Flattening combines the watermark and document pixels and removes the embedded selectable text layer. It does **not** prevent image editing, watermark removal attempts, or later OCR. Image exports remove source EXIF/GPS metadata; standard PDFs are not guaranteed to be sanitized. See [SECURITY.md](SECURITY.md).

Limits: 100 MiB per input, 50 PDF pages, and 20,000 pixels per image side. Password-protected PDFs are rejected. Transparency is converted to opaque output.

## Command line

The app contains a `pwm` command that watermarks files without opening the window. It uses the app's validation, rendering, naming and export, so its copies are the same as the app's for the same settings. It is at `/Applications/Privacy Watermark.app/Contents/MacOS/pwm`. To type just `pwm`, link it with the [Finder Quick Action installer](#finder-quick-action) (`install.sh --link`). From a checkout, use `swift run pwm …` instead.

```sh
pwm "COPY" passport.jpg
pwm "For rental file" id.jpg payslip.pdf --date
pwm "Rental application\nAgency only" lease.pdf --format png --out Shared
pwm --text "COPY" -- -scan.pdf
pwm --help
```

The first argument is the watermark text, unless `--text` or a preset gives it. Every other argument is an input file. Options can go anywhere, and `--` ends options so a file name can start with `-`. Type `\n` for a line break. Text, including the date line, is limited to 200 characters. Longer text is an error and is never shortened.

| Option | Values | Default |
|---|---|---|
| `--date` / `--no-date` | Add today's `DD-MM-YYYY` line, or not | off |
| `--opacity` | 0–100 | 30 |
| `--size` | 12–72 | 36 |
| `--spacing` | 50–300 | 150 |
| `--color` | `white`, `black`, `gray` | `black` |
| `--direction` | `up`, `down` | `up` |
| `--format` | `keep`, `pdf`, `jpg`, `png` | `keep` (PDF→PDF, PNG→PNG, JPG→JPG) |
| `--pdf-mode` | `flattened`, `text` | `flattened` |
| `--dpi` | 300, 450, 600 | 450 |
| `-o`, `--out` | An existing, writable folder | beside each source |

Without `--out`, each copy is saved beside its original, with the app's names: `passport_watermarked.jpg`, then `passport_watermarked (2).jpg`, and a `lease_watermarked` folder for PDF page images. Originals and existing files are never changed. The same file given twice, including through a link, is processed once. Unsupported, missing, too-large or password-protected inputs, and folders, are excluded and do not stop the others.

Standard output lists only the saved copies, one path per line, so scripts can use them. Reasons and the summary, such as `2 saved · 0 failed · 1 excluded · 0 not processed`, go to standard error. Neither contains the watermark text.

| Exit status | Meaning |
|---|---|
| 0 | Every input was saved |
| 1 | Some inputs were saved; others failed, were excluded or were not processed |
| 2 | No input was saved |
| 64 | Invalid command line, or `--out` is not a writable folder |
| 78 | Invalid preset file |
| 130 | Interrupted with Control-C. Completed copies stay; the unfinished one is removed |

### Presets

Save text and settings you reuse in `~/.config/pwm/presets.json`, or in `$XDG_CONFIG_HOME/pwm/presets.json` when `XDG_CONFIG_HOME` is set. A preset can set `text`, `date`, `opacity`, `size`, `spacing`, `color`, `direction`, `format`, `pdf-mode` and `dpi`, with the same values as the options:

```json
{
  "presets": {
    "rental": { "text": "Rental application", "date": true, "opacity": 40 },
    "bank": { "text": "For Example Bank only", "color": "gray", "direction": "down", "dpi": 600 }
  }
}
```

```sh
pwm --list-presets
pwm --preset rental id.jpg payslip.pdf
pwm --preset rental id.jpg --opacity 20 --text "Guarantor file"
```

With a preset that sets text, every argument is an input file. Options on the command line, including `--text`, `--date` and `--no-date`, override the preset. `pwm` only reads this file and never creates or changes it. **The file can contain private watermark text**: keep it out of shared dotfile repositories and backups you publish.

### Removing photo metadata only

```sh
pwm --strip-only IMG_0042.jpg
```

`--strip-only` saves `IMG_0042_stripped.jpg` without a watermark and without source EXIF, GPS, camera or timestamp metadata. It accepts JPG and PNG only. PDFs are excluded, and watermark, format and preset options are refused. The image is re-encoded like any image export: PNG stays lossless, but JPG is saved again at 90% quality, which loses a little detail, and transparency becomes opaque. Like the app's image export, it does not apply the EXIF orientation tag, so a photo that relies on that tag to appear upright is saved sideways.

## Finder Quick Action

The **Watermark** Quick Action watermarks selected JPG, PNG and PDF files from Finder without opening the app window. Copies are saved **beside the originals**, with the same names and rules as `pwm`, and the originals are never changed.

**Install.** Open Privacy Watermark from Applications once first, and approve it in **System Settings → Privacy & Security** if macOS asks: until then, macOS can block the Quick Action from running the app's `pwm`. Then, in Terminal:

```sh
"/Applications/Privacy Watermark.app/Contents/Resources/quick-action/install.sh"
```

Add `--link` to also make `pwm` available as a command in `~/.local/bin`, or `--link DIR` for another folder. If that folder is not on your `PATH`, the installer says how to add it. The installer works for your account only, asks for no administrator password and changes no security setting. From a checkout, run `scripts/build-app.sh` and then `scripts/quick-action/install.sh`.

**Use.** In Finder, select one or more JPG, PNG or PDF files, Control-click and choose **Quick Actions → Watermark**. It is also in the Finder Preview pane. If you have [presets](#presets), choose one or **Custom text…**. Otherwise, type the watermark text and click **With date** (the default, which adds today's `DD-MM-YYYY` line) or **Without date**. Type `\n` for a new line. Text over 200 characters is refused, and you can edit it and try again. Other settings use the app's defaults, or the preset's, and each file keeps its format. **Cancel** writes nothing.

When every file is saved, a notification gives the number of copies. Otherwise, an alert lists each file that was not watermarked with its reason, and **Reveal in Finder** selects the copies that were saved. Feedback never shows the watermark text, and nothing is logged.

The first time, macOS may ask to allow notifications, and to allow control of Finder for **Reveal in Finder**. These requests name Automator or Script Editor, which run Quick Actions; allow them once. macOS may install **Watermark** turned off. If it is missing from the menu, turn it on once in Finder's **Quick Actions → Customize…**, in **System Settings → General → Login Items & Extensions → Finder**, or in **System Settings → Keyboard → Keyboard Shortcuts… → Services → Files and Folders**.

If you move the app, the Quick Action still finds it in `/Applications` or `~/Applications`. If the app is removed, the Quick Action explains how to restore it and processes nothing.

**Uninstall.**

```sh
"/Applications/Privacy Watermark.app/Contents/Resources/quick-action/uninstall.sh"
```

This removes the Quick Action and the `pwm` link the installer made. It does not touch the app, your presets or your documents.

## Build and install

Install a Swift 6 toolchain through Xcode 16 or newer, or compatible Xcode Command Line Tools. Then, from this checkout:

```sh
scripts/build-app.sh
open "dist/Privacy Watermark.app"
```

The script builds and verifies a universal app containing both `arm64` and `x86_64` slices. Copy `dist/Privacy Watermark.app` to your Applications folder to install it. The built app needs no separately installed language runtime or third-party dependencies.

The local bundle is **ad-hoc signed**, not Developer ID signed or notarized. A notarized public release is not produced by this script. macOS may require approval in Privacy & Security for a downloaded copy.

To build the drag-to-Applications installer, see [DMG packaging and release instructions](docs/releases/README.md). Packaging tools are needed only on the build Mac and are not included in the downloaded app.

For development without bundling:

```sh
swift run PrivacyWatermark
scripts/test.sh
```

To exercise the native window, file-panel cancellation and export workflow in a logged-in graphical macOS session:

```sh
scripts/build-app.sh
scripts/smoke-test.sh
```

CI is configured for native tests, universal builds, built-app launch and window/export smoke checks on macOS 14 Apple Silicon and macOS 15 Intel. See the [batch acceptance record](docs/batch/acceptance.md) for current results and pending checks; the [migration record](docs/migration/acceptance.md) retains historical evidence.

Watermark size and spacing now scale relative to each document's shorter side,
using A4 as the baseline. Images and non-A4 PDFs intentionally differ from older
exports. PDFs scroll continuously; pinch or Command + wheel zooms around the
pointer. See the [preview acceptance record](docs/preview/acceptance.md) for tests,
screenshots, and user acceptance.

## Source layout

- `Sources/PrivacyWatermark`: native window, session and file dialogs.
- `Sources/WatermarkCore`: validation, rendering, encoding and transactional export.
- `Sources/PWMCommand` and `Sources/pwm`: the `pwm` command line.
- `scripts/quick-action`: the Finder Quick Action and its install scripts.
- `tests`: native behavior tests and synthetic fixtures.
- `scripts`: universal bundling and verification. `python3 scripts/test-quick-action.py` tests the Quick Action scripts.

## License

Personal project — free to use for personal and non-commercial purposes.

Louni Merk — 2026
