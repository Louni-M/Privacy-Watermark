# Passport Filigrane

A native macOS app for watermarking images and PDFs together before sharing copies. Built with SwiftUI, PDFKit, Core Graphics and ImageIO; all processing stays on your Mac.

Requires **macOS 14 or newer**, on Apple Silicon or Intel.

## Download for Mac

**[Download for Mac](https://github.com/Louni-M/Privacy-Watermark/releases/latest/download/Passport-Filigrane.dmg)** · Version 2.0.2 · 3.0 MB

Install in three steps:

1. Download `Passport-Filigrane.dmg` and double-click it.
2. Drag **Passport Filigrane** onto **Applications** in the installation window.
3. Wait for copying to finish, eject the disk image, and open the app from Applications.

This free release is **ad-hoc signed and not notarized by Apple**. If macOS says Apple could not verify the app is free of malware, click **Done**, then open **System Settings → Privacy & Security → Open Anyway**, then confirm and authenticate if asked. Only approve a download you trust. The approval button is available for about an hour after attempting to open the app. See [installation help](assets/dmg/Install.txt), also included in the DMG, for missing approval controls or other warnings.

## Use

1. Choose **Add files** or press **⌘O** to select JPG, JPEG, PNG and PDF files, or drag files into the window. Later additions append to the list; repeated additions of the same file are ignored.
2. Enter the shared watermark text. Expand **Appearance** to adjust opacity, size, spacing, color and diagonal direction for every file.
3. Select a file to inspect it. PDF arrows navigate every page; use zoom and scrolling for details, or **Fit to window** for the whole page.
4. Keep each input's original format, or choose PDF, JPG or PNG for the batch. Choose **Export all…** and one destination folder. Your originals stay unchanged.

Remove individual files or choose **Clear all** to empty the list. Shared settings survive additions, removals and selection changes; restarting restores defaults and an empty batch. Selecting another file resets page and view to the first page and Fit. Changing PDF page preserves your zoom.

Copies use `<name>_watermarked.ext`, adding ` (2)`, ` (3)` and so on when names are already used. PDFs converted to images get a separate `<name>_watermarked` folder containing numbered `<name>_page_001.jpg` or `.png` files. Inputs are never merged, existing destinations are never replaced, and another export creates new copies. This folder workflow also applies to one file; PNG input defaults to PNG.

Files validate progressively. Invalid files stay visible and do not prevent valid files from exporting once checking finishes. During export, you can browse previews or **Cancel**; collection and shared settings are locked. Cancellation keeps completed copies and removes unfinished output. The summary distinguishes saved, failed and unprocessed files. If a queued source changes or becomes unavailable, restore access and remove/add it again to review its current content.

After an export saves files, **Reveal in Finder** appears below the export summary at the bottom of the preview pane. It selects the saved copies in Finder, including completed outputs from a cancelled or partially failed export.

| Input | Output |
|---|---|
| JPG / PNG | JPG, PNG, or single-page PDF |
| PDF | PDF, or one JPG / PNG file per page |

PDF export defaults to **Flattened at 450 DPI**, with 300 and 600 DPI available. **Selectable text** mode preserves source text and adds a separate vector watermark. PDF page images retain the existing 72-DPI output sizing.

Flattening combines the watermark and document pixels and removes the embedded selectable text layer. It does **not** prevent image editing, watermark removal attempts, or later OCR. Image exports remove source EXIF/GPS metadata; standard PDFs are not guaranteed to be sanitized. See [SECURITY.md](SECURITY.md).

Limits: 100 MiB per input, 50 PDF pages, and 20,000 pixels per image side. Password-protected PDFs are rejected. Transparency is converted to opaque output.

## Build and install

Install a Swift 6 toolchain through Xcode 16 or newer, or compatible Xcode Command Line Tools. Then, from this checkout:

```sh
scripts/build-app.sh
open "dist/Passport Filigrane.app"
```

The script builds and verifies a universal app containing both `arm64` and `x86_64` slices. Copy `dist/Passport Filigrane.app` to your Applications folder to install it. The built app needs no separately installed language runtime or third-party dependencies.

The local bundle is **ad-hoc signed**, not Developer ID signed or notarized. A notarized public release is not produced by this script. macOS may require approval in Privacy & Security for a downloaded copy.

To build the drag-to-Applications installer, see [DMG packaging and release instructions](docs/releases/README.md). Packaging tools are needed only on the build Mac and are not included in the downloaded app.

For development without bundling:

```sh
swift run PassportFiligrane
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

- `Sources/PassportFiligrane`: native window, session and file dialogs.
- `Sources/WatermarkCore`: validation, rendering, encoding and transactional export.
- `tests`: native behavior tests and synthetic fixtures.
- `scripts`: universal bundling and verification.

## License

Personal project — free to use for personal and non-commercial purposes.

Louni Merk — 2026
