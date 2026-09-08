## Why

The same watermark settings produce tiny, densely repeated text on high-resolution photos and much larger text on PDFs. Preview navigation also needs continuous scrolling and smooth zoom, and long selected filenames need more space.

## What Changes

- Scale watermark text and spacing relative to the shorter displayed document side, using A4 PDF dimensions as the baseline, consistently in preview and export.
- **BREAKING**: Replace the legacy pixel/point sizing rule; newly generated images and non-A4 PDFs intentionally change watermark proportions. Existing files are unaffected.
- Show PDF pages in a continuous vertical preview with trackpad and mouse scrolling; retain page buttons as smooth navigation shortcuts.
- Support smooth pinch zoom, Command + mouse wheel zoom, and animated zoom buttons while preserving the focused document position.
- Fit the current PDF page to the window while retaining continuous scrolling; selecting another file starts at its first page, fitted.
- Put the selected filename in a full-width row above the preview, allowing two lines and exposing the full name on hover.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `native-watermark-workflow`: Relative watermark settings, continuous preview navigation, smooth anchored zoom, current-page fitting, and readable filenames.
- `document-export-parity`: Consistent relative watermark geometry across source types and all export routes, replacing legacy density equivalence.

## Impact

Changes affect the shared renderer and its export callers, preview rendering/worker, session navigation state, AppKit preview host, SwiftUI header, and associated tests and acceptance notes. Keep native macOS frameworks and existing local-processing, file-validation, export-quality, metadata, source-preservation, and PDF semantics guarantees. No new service or dependency is expected.

## Non-goals

No opacity-model changes, image resizing, export-resolution changes, merged files, editing tools, per-file settings, remembered per-file viewport, or wider sidebar redesign. This change ends with implementation and acceptance evidence; publishing a release is a separate action.
