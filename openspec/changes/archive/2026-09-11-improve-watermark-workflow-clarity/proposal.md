## Why

First-time users face a subdued import action, unexplained appearance numbers, and limited guidance about watermark text and export results. Make the path from adding documents to understanding and exporting marked copies immediately clear, while preserving the existing local processing and file-handling contracts.

## What Changes

- Give the empty state a prominent Add files action, an outlined drop area, and an interactive fictional document labeled Sample preview; hide the Files column until items exist.
- Replace Help write my watermark with an Include today’s date checkbox below the text editor; insert/remove an editable DD-MM-YYYY line with no label or prefix and zero-padded month and day, while retaining COPY as the default.
- Widen the resizable settings panel, improve supporting text and contrast, and keep Appearance collapsed initially.
- Make the unfilled portion of appearance slider tracks black instead of grey, matching the dark background while retaining the blue filled portion and light thumb.
- Add editable appearance numbers, explain document-relative size and spacing, and provide Reset appearance without resetting text or export choices.
- Show a live export summary of eligible source documents, output file counts and formats, and PDF page-image folders; label the action Export N documents… with singular handling.
- Show accurate reassurance: Processed on your Mac. Originals stay unchanged.
- Preserve blank text and zero opacity without warnings, extra confirmations, or export restrictions, as explicitly requested by the operator.

## Capabilities

### New Capabilities

None; these changes extend the existing watermark workflow and rendering contract.

### Modified Capabilities

- `native-watermark-workflow`: First-use sample, optional today-date insertion, multiline editor, readable resizable controls, precise appearance editing, reset scope, export explanation, and local-processing reassurance.
- `document-export-parity`: Consistent multiline watermark layout in previews and every output route while retaining existing single-line geometry and output semantics.

## Impact

- Native UI and session state in Sources/PassportFiligrane, plus shared watermark text layout in Sources/WatermarkCore.
- Synthetic sample content, focused native/core tests, and recorded visual acceptance of the complete workflow.
- Existing format matrix, file limits, destination dialogs, naming, cancellation, source preservation, PDF modes, metadata behavior, local-only processing, and macOS 14 Apple Silicon/Intel support remain unchanged.
- No accounts, networking, saved presets, per-file settings, distribution changes, or installation work. This proposal covers planning only; implementation follows a separate apply request.
