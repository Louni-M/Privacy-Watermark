# Implementation acceptance — 15 September 2026

## Result

Implemented adaptive shared watermark geometry, a fixed export action area, separate validation exclusions, and output controls based on eligible PDF routes. This record covers implementation verification before release. Publication evidence is recorded separately in docs/releases/acceptance.md.

The whole watermark block is measured with font fallback and explicit blank lines. Safe legacy single-line geometry is retained; colliding layouts use larger horizontal/vertical pitches with proportional clearance. Oversized text anchors actual ink, falling back to a real glyph when a very wide line has a blank center. The entered spacing, font size, and text stay unchanged. Regional previews derive the pattern from the full page.

## Automated evidence

- Final test run: **60 tests in 16 suites passed**, including the expanded visual-comparison test and native light/dark window rendering.
- Regression coverage includes both diagonals, accented names/date, long lines, combining marks, emoji/CJK, maximum text size/minimum spacing, 198 blank lines, leading/trailing spaces, and a wide line with only a glyph at each end. Tests check block/line separation, visibility, monotonic separation, bounded work, default COPY pixel compatibility, and existing normalized preview/export parity.
- The whitespace regression initially failed on four cases and passed after anchoring visible ink. A direct system `swift test` invocation lacked the Testing module; repository `scripts/test.sh` uses the configured toolchain and passed.
- Export tests cover three valid plus three invalid documents, attempted failures, cancelled work with exclusions, unavailable sources, and a subsequent run excluding a newly invalid source. Every source is counted once.
- Output-control tests cover empty, image-only, invalid-PDF and mixed batches; PDF, original, PNG and JPG policies; retained mode/quality choices.
- Extended processing run passed the format/quality matrix and synthetic 50-page export/cancellation checks. This uses the repository's default **debug test configuration**, despite the existing benchmark JSON's hardcoded Release description. The small-page stress fixture and shared process-memory measurements are not representative of an isolated 50-page A4 scan workload.
- Universal release app build verifies arm64 and x86_64 slices and ad-hoc signature. Only arm64 runs on this Mac.
- Standard native smoke passed import, panel cancellation, navigation/zoom/pan, selection/duplicates/removal, original-format and page-image exports, failure/cancellation handling, and reopened output checks.

Local logs: `/tmp/privacy-watermark-apply-final.log`, `/tmp/privacy-watermark-apply-extended.log`, `/tmp/privacy-watermark-apply-final-build.log`, and `/tmp/privacy-watermark-apply-final-smoke.log`.

## Visual and interaction checks

- Rebuilt app: three-line rental-purpose/name/date text has separated repetitions in the sample and selected synthetic photo preview. The saved manual PNG matches the visible preview.
- At actual **860 × 600-point** hosting-view bounds, native tests asserted dimensions and captured both appearances with a mixed batch and Appearance expanded. Inspected light/dark images show the action/count below the scrolling settings, readable editing controls and an unobstructed preview. This evidence supersedes the inconclusive minimum-size screenshots in the initial review; the separate window-manager stress harness was not claimed to pass.
- Scrolling expanded settings in the real app leaves Export visible. Switching the batch to PNG hides PDF processing/quality and states 72-DPI page-image sizing.
- Manual export of six synthetic inputs reports **3 saved · 0 failed · 3 excluded · 0 not processed**, producing four PNG files. A second export produced numbered copies and a second PDF-page folder. Reveal in Finder selected the two newly exported page images.
- Keyboard import and export shortcuts worked. The accessibility tree exposes named editor, date, numeric fields, sliders, appearance/reset, export, and reveal actions. This is accessibility inspection, not a full VoiceOver user session.
- Inspected saved/fit/zoom comparison sheets for the rotated PDF page across standard PDF, flattened 300/450/600 DPI, PNG and JPG, covering both diagonal directions. The three-line watermark is separated and consistently positioned. Generated comparisons also cover image inputs and differently sized pages; not every generated sheet was manually inspected.

Ignored local artifacts live in `.build/apply-layout/`: `final-native/`, `final-comparisons/`, `multiline-comparisons/`, `benchmarks/`, `final-smoke/`, and `manual-exports/`. The visual manifests identify saved, fit, and panned/zoomed columns.

## Remaining manual acceptance

Task 5.4 remains open for a physical trackpad pinch/momentum check, a full VoiceOver interaction session, and a fresh Finder drag-and-drop check. Existing keyboard, native cancellation, duplicate-naming, and Reveal in Finder checks passed. No macOS 14 or Intel runtime was available in this session. These limits do not indicate observed defects and are not silently marked as passes.
