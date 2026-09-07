## Why

Passport Filigrane should feel like a simple Mac utility: open a document, adjust a watermark, preview, and export. The current Python/Flet interface and bundled runtime add maintenance and launch overhead; the user wants a native replacement with faster launch and previews, all existing capabilities, and a clean repository after migration.

## What Changes

- Replace Python/Flet/Pillow/PyMuPDF with Swift, SwiftUI, and Apple's native document and image frameworks.
- **BREAKING:** Target macOS 14 or newer on Apple Silicon and Intel; retire the Python entry point and cross-platform source execution after verification.
- Simplify the interface around open, watermark text, preview, and export, with less-used appearance controls in an expandable section.
- Preserve JPG/JPEG, PNG, and PDF input; the complete existing export matrix; first-page PDF preview; all watermark adjustments; image metadata stripping; validation limits; and understandable errors.
- **Behavior change:** Default PDF processing to flattened output at 450 DPI. Keep standard selectable-text PDF output and 300/450/600 DPI choices available.
- Accept minor differences in font rendering, but require equivalent readability, watermark behavior, and document quality.
- Verify faster launch and preview updates and no material export slowdown against the Python app on the same Mac.
- Keep the Python implementation only during comparison. After acceptance, remove its code, dependencies, packaging, obsolete tests, and temporary comparison tooling; replace CI and documentation with the native workflow.

## Capabilities

### New Capabilities

These are new specification entries for existing behavior and the approved migration; no main capability specs currently exist.

- `native-watermark-workflow`: Native single-document workflow, simplified controls, first-page live preview, defaults, and recovery from failure.
- `document-export-parity`: Supported formats, watermark semantics, standard and flattened PDF output, privacy, validation, and safe repeatable exports.
- `native-app-delivery`: macOS compatibility, reproducible app packaging, performance and parity acceptance, and mandatory legacy cleanup.

### Modified Capabilities

None; there are no existing main specs to modify.

## Impact

Replaces `main.py`, `app.py`, `watermark.py`, `pdf_processing.py`, `utils.py`, `constants.py`, Python requirements files, `Passport Filigrane.spec`, and Python-specific tests. Updates `.github/workflows/ci.yml`, `README.md`, `SECURITY.md`, and relevant ignore rules. Retains app identity/icon and useful synthetic fixtures and reference evidence. Adds Swift source, native tests, app packaging, and acceptance records. No server, account, telemetry, new document formats, batch workflow, or App Store launch is introduced. Existing downloadable `.app` distribution remains the baseline; developer signing and notarization are a separate release concern.
