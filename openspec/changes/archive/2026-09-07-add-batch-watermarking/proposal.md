## Why

Watermarking several documents currently means opening, reviewing and exporting them one at a time. Users need to gather mixed images and PDFs, apply one watermark to the whole batch, inspect any file or PDF page, and export clearly named copies in one operation.

## What Changes

- Replace the single-document session with a batch that accepts JPG/JPEG, PNG and PDF through Add files and drag-and-drop. Append new files, remove individual items, clear the list, and ignore repeated additions of the same file while retaining distinct files with matching names.
- Share watermark text and appearance across all files. Keep the existing settings, rendering rules, privacy behavior and flattened 450-DPI PDF default.
- Show a file list beside one large selected preview, PDF page navigation, zoom and Fit to window. Preview must reflect the selected file/page and effective export settings without stale results.
- Default to each input's format, with one optional batch-wide conversion to PDF, JPG or PNG. Each input remains a separate output document; PDFs exported as images get their own numbered-page folder.
- Choose one destination folder and name copies `<stem>_watermarked`, adding numbers on collisions. **BREAKING**: this replaces the fixed `export_filigree` basename and replacement prompts in the UI, including a batch containing one file; PNG input now defaults to PNG instead of JPG.
- Display per-file failures and continue with valid files. Show file-based progress and cancellation that retains completed copies and removes unfinished output.
- Verify responsiveness using 100 mixed files, preserving existing per-file limits. This is a performance target, not a new hard file-count cap.

## Capabilities

### New Capabilities

- `batch-watermark-export`: appendable mixed-file collection, duplicate handling, shared export policy, safe naming, progress, failure isolation, cancellation and large-batch acceptance.

### Modified Capabilities

- `native-watermark-workflow`: evolve the existing window, shared settings, selected preview and recovery behavior for a batch and all-page PDF inspection.
- `document-export-parity`: preserve the conversion matrix while changing page-series organization and destination naming to safe batch exports.

## Impact

Affected areas are the SwiftUI window and session, document loading lifecycle, page-addressable preview rendering, export destination planning, cancellation/commit boundaries, native tests, smoke checks and user documentation. Retain the existing native processing core and macOS 14 Apple Silicon/Intel support; no new runtime dependency or network service is required.

The completed migration specs have been synced as the baseline, and the migration is archived at `openspec/changes/archive/2026-09-07-migrate-to-native-macos`. Implementation must retain its validated processing behavior and replace obsolete single-document UI tests.

GitHub downloads, installation wizards, release packaging, signing/notarization, per-file watermark overrides, saved batches/presets, PDF merging, folder recursion and automatic watermark-size normalization are outside this change. No implementation is performed by this proposal.
