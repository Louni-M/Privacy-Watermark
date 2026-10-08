## Why

The hands-on review reproduced collisions between repeated watermark blocks in both the preview and saved images, especially with longer multiline text and an added date. Export controls and result wording also obscure what will be saved and whether a failure occurred, despite the tested export pipeline working correctly.

## What Changes

- Measure complete text blocks and expand repetition spacing when necessary to prevent neighboring stamps from overlapping, while preserving explicit line breaks, chosen text size, direction, and preview/export parity.
- Preserve existing short, non-overlapping single-line layouts; deliberately change layouts that currently collide. Keep the spacing control as a requested minimum pitch with an automatic readable minimum.
- Keep the export action and a concise eligible-document count visible while appearance controls scroll at supported window sizes.
- Distinguish validation exclusions from failures during an export attempt and from eligible documents left unprocessed after cancellation.
- Show PDF processing controls only for eligible PDF inputs whose effective output is PDF; show flattening quality only when it applies. Clearly identify PDF page-image output as fixed at 72 DPI without an unrelated quality selector.
- Retain current output dimensions, PDF modes, naming, offline processing, and source protection. This proposal does not add higher-resolution PDF-to-image export.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `document-export-parity`: Collision-free repeated watermark geometry with consistent previews and all export routes; qualify legacy geometry preservation to layouts that do not collide.
- `native-watermark-workflow`: Persistent export action, applicable PDF quality controls, clearer outcomes, and a brief explanation of automatic minimum spacing.
- `batch-watermark-export`: Separate excluded inputs from attempted failures in run accounting and result summaries.

## Impact

- Core rendering and geometry: `Sources/WatermarkCore/Renderer.swift`, with shared layout used by sample, image/PDF preview, and all export paths.
- Export accounting: `Sources/WatermarkCore/BatchExport.swift`, related summary models, and `Sources/PrivacyWatermark/Session.swift`.
- Native UI: `Sources/PrivacyWatermark/ContentView.swift` and appearance controls in `WorkflowControls.swift`.
- Existing rendering, batch, session, and native-window tests; README behavior descriptions and acceptance evidence.
- No added network services or runtime dependencies. No source document migration. Existing numerical settings remain valid, but formerly overlapping patterns intentionally render with fewer, separated repetitions.

See `review.md` for verified findings, test coverage, and limitations. Implementation progress is tracked in tasks.md; see acceptance.md for verification and remaining manual checks.
