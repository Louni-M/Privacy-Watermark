# Passport Filigrane

A native macOS app for adding a watermark to a document before sharing a copy. Built with SwiftUI, PDFKit, Core Graphics and ImageIO; all processing stays on your Mac.

Requires **macOS 14 or newer**, on Apple Silicon or Intel.

## Use

1. Choose **Open** or press **⌘O** to select a JPG, JPEG, PNG or PDF.
2. Enter the watermark text. Expand **Appearance** to adjust opacity, size, spacing, color and diagonal direction.
3. Choose an output format and **Export copy…**. Your original stays unchanged.

The preview shows the image or first PDF page; export processes every page. Settings persist while switching documents during the session.

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

CI runs native tests, universal builds, built-app launch and window/export smoke checks on macOS 14 Apple Silicon and macOS 15 Intel. The [migration acceptance record](docs/migration/acceptance.md) contains measured performance and retained validation evidence.

## Source layout

- `Sources/PassportFiligrane`: native window, session and file dialogs.
- `Sources/WatermarkCore`: validation, rendering, encoding and transactional export.
- `tests`: native behavior tests and synthetic fixtures.
- `scripts`: universal bundling and verification.

## License

Personal project — free to use for personal and non-commercial purposes.

Louni Merk — 2026
