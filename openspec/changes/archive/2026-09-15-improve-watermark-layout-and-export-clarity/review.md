# Privacy Watermark application review — 15 September 2026

## Assessment

The tested import/export foundation is solid. The app is focused, provides a useful live sample, handles mixed documents and invalid inputs without blocking good files, and protects existing files. The main weakness is readability: repeated long or multiline watermarks can overlap, and several export UI details make a successful operation harder to understand.

This is a broad local review, not a claim that every device, document, gesture, or failure mode has been tested. No application source code was changed during the review.

## Findings, in priority order

| Priority | Finding | Evidence and recommendation |
|---|---|---|
| High | Repeated watermark text collides | Reproduced using a three-line purpose/name/date watermark at size 36 and spacing 150; also visible in saved PNG. The renderer measures the text but keeps fixed repetition pitches. Measure the rotated block and enforce minimum separation in the shared renderer. |
| Medium | Export action disappears below the fold | Observed with Appearance expanded and mixed inputs on this Mac. Keep a compact action/count area fixed while detailed settings scroll. |
| Medium | Irrelevant PDF quality control appears for PNG export | PNG selected while the UI still showed Flattened and 450 DPI. Exported 400 × 280-point PDF page was 400 × 280 pixels, consistent with the fixed 72-DPI contract. Hide unrelated selectors and state actual page-image resolution. |
| Medium | Validation exclusions become “failed” in the result | Three good and three invalid inputs exported as “3 saved · 3 failed · 0 not processed”; four PNG outputs existed. Separate excluded from attempted failures. |
| Low / follow-up | File list is visually busy | Every row repeats a truncated folder path, status, and Remove action. Consider emphasizing filename and status, showing location on hover except for duplicate names, while preserving accessible removal and same-name disambiguation. This polish is outside the current implementation proposal. |

## What worked well

- Live sample updates before import; explicit multiline text, accented characters, and date insertion worked.
- Numeric opacity clamped to 100 when 150 was committed; invalid text-size input reverted to the previous valid value. Reset restored appearance while retaining watermark text.
- Mixed batch append and duplicate suppression worked; invalid, password-protected, and 51-page PDFs gave specific messages.
- PDF page navigation and zoom retention worked; source rotation was retained.
- Color and direction controls responded; changing export format changed preview appearance and output prediction.
- Manual PNG export saved all three valid source documents, producing four files because the PDF had two pages.
- Repeating export created another numbered output folder and numbered image copies. Eight output images existed after two runs.
- The six copied input fixtures remained byte-for-byte identical to their originals.
- Reveal in Finder opened the saved PDF-page folder and selected both exported page images.
- Representative saved/fit/zoom comparison for the rotated flattened PDF page was visually consistent.

## Automated verification

- Default `scripts/test.sh`: successful, reported 55 tests in 15 suites; opt-in performance/visual evidence checks were skipped in that first run.
- Extended test run enabled native screenshots, processing benchmarks, corpus generation, and visual comparisons: successful, reported 55 tests in 15 suites, including the previously gated processing and 50-page stress checks. Tests used the default debug configuration; a benchmark JSON description says “Release,” but the command did not request release, so do not interpret these measurements as release benchmarks.
- Universal release app build and signature/architecture verification: successful for arm64 and x86_64. Only arm64 executed on this Mac.
- Standard native smoke checks: successful, covering native launch, panel cancellation, mixed import, navigation, duplicate/removal behavior, original-format and PNG export, write errors, cancellation, and output reopen.
- Extended native preview stress: stopped at the window-size assertion. Requested 860 × 600 content, observed 1424 × 854. Its later navigation stress stages did not run. The normal smoke screenshots labelled minimum-window also captured larger content, so they are not proof of minimum-size compliance.
- Separate processing stress successfully exported and reopened a synthetic 50-page flattened PDF at 600 DPI and exercised cancellation at a page boundary. The fixture has small pages; it is not equivalent to a 50-page full-resolution scanned A4 document. Reported process peak memory is shared test-process usage, not an isolated per-export measurement.

## Limits and follow-up acceptance

Physical trackpad pinch/momentum, Finder drag-and-drop, VoiceOver, light appearance, a genuine 860 × 600 window, macOS 14, and Intel runtime behavior were not manually verified in this session. No fresh 100-document end-to-end UI export was run. Do not claim those passed based on the local results. The extended suite generated comparison sheets; only representative sheets were manually inspected.

## Evidence

Generated local evidence is under `.build/review-2026-09-15/` and is ignored by git:

- `smoke.json`, `bundle-launch.json`, `window.png`, `minimum-window.png`
- `stress/smoke.json` (window-size failure)
- `manual-inputs/` and `manual-exports/` (synthetic fixtures and saved collision examples)
- `native/`, `benchmarks/native-processing.json`, `benchmarks/native-stress.json`
- `comparisons/visual-manifest.json` and comparison images
- `corpus/`

Source anchors: Renderer.swift:55–134 (fixed pitches); ContentView.swift:16–23 and 176–197 (scrolling action and PDF controls); BatchExport.swift:46–56 and 93–138 (outcome accounting). The associated design and delta specs turn the four prioritized findings into implementation and acceptance criteria.
