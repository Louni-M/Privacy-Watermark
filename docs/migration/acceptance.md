# Native migration acceptance record

Status: behavior, performance and compatibility acceptance passed. Final cleanup verification is in progress.

## Environment and reference

Recorded 2026-09-07 on an Apple M3 with 16 GiB RAM, macOS 26.6.2 (25G83), Swift 6.3.3 Command Line Tools. Release optimization was used for timing. The legacy reference is revision `752369ed5b6abc8c395a23ab1a240d77cd3508fc`; exact Python dependencies are in `legacy-environment.txt`. Legacy tests: 119 passed, 1 skipped, 5 dependency deprecation warnings (`legacy-tests.txt`).

The retained synthetic corpus is `tests/WatermarkCoreTests/Fixtures`. SHA-256 identities are recorded in `legacy-processing.json`. It covers metadata-bearing and EXIF-oriented photos, opaque and transparent PNGs, text/vector PDFs with annotations, links, form appearances, crop boxes and rotation, a scanned PDF, 10/50/51-page documents, and invalid/protected PDFs. It contains no personal documents.

Known legacy defects deliberately fixed: standard export mutated the source PDF, repeated exports could accumulate watermarks, and image export could reuse stale-format preview bytes. Image EXIF orientation is not newly applied: raw pixel dimensions/orientation follow the reference. Transparent inputs retain legacy RGBA compositing followed by opaque RGB output, including hidden RGB where no watermark is drawn.

## Requirement evidence

| Specification requirement | Evidence |
|---|---|
| Single-document native workflow | `ContentView`, `SessionTests`, real NSApplication window capture and `native-window-smoke.json`; empty state and replacement Open cancellation |
| Preserve watermark settings | Defaults, all colors/directions, 12–72 size, 50–300 spacing, opacity limits, empty text, 200-character validation; `DocumentTests` and session file-switch test |
| Flattened PDF default and clear mode choice | `testDefaults`, session defaults/file switching, window smoke; initial flattened 450 DPI, 300/600 choices, standard selectable-text alternative |
| Responsive and accurate preview | Session stale-load/preview tests, independently captured export snapshots, `native-preview-timings.json`; first-page-only preview with 120 ms debounce |
| Recoverable failures and export feedback | Session invalid replacement/recovery and export recovery tests; actual native Open/Save/folder cancellation in `SmokeTest.swift` |
| Complete format matrix | Image and PDF matrix tests; independent Pillow/PyMuPDF reopen of all output routes, page-series count/order/names and 72-DPI dimensions |
| Equivalent watermark and output quality | `visual-review.pdf`: reference/native pairs for standard and flattened PDFs, rotated/cropped second page, all four image fixtures, all colors and both directions at representative size/spacing/opacity boundaries; zero/empty settings additionally tested |
| Standard PDF semantics | `testStandardPDFPreservesTextGeometryAndLinks`; independent `native-pdf-inspection.json` verifies source/COPY/annotation/form text, link target, geometry, and absence of whole-page image flattening |
| Flattened PDF semantics | Every 300/450/600 output independently inspected for page size, embedded pixel dimensions (within rounding), single image per page and no extractable text; all images in page order |
| Local processing and image metadata removal | No network client or telemetry in sources; core/session tests passed under `sandbox-exec` denying network; image metadata and encoded-container tests; `embedded-image-inspection.json`: 93 freshly generated embedded JPEGs contain no source EXIF/GPS; standard scan PDF retains source metadata as documented |
| Preserve validation boundaries | Valid exact-100-MiB JPEG, 20,000/20,001-pixel images, 50/51 pages, encrypted/empty/corrupt/unsupported files; readable error categories |
| Repeatable exports and source preservation | Original source byte checks, repeated exports, latest settings, hardlink/symlink identity protection, existing-destination handling, staged multi-file rollback test |
| Supported native application | Universal ARM/Intel bundle, macOS 14 deployment, ad-hoc signature verification; built-bundle window launch plus processing/UI smoke on actual macOS 14 ARM and macOS 15 Intel CI runners |
| Behavioral acceptance evidence | This mapping, native tests, retained visual review, independent inspection, runtime reports and raw timings |
| Measured performance improvement | Raw launch/UI preview/processing/paired timings and `performance-comparison.json`; methods and limitations below |
| Mandatory legacy retirement | Final native-only repository/build/bundle audit recorded below after cleanup |

The output review found matching readable document content, colors, directions, displayed geometry, annotation/form appearances and opaque image behavior. Font antialiasing and tile origins differ; watermark size, spacing and coverage remain equivalent. White watermarks on white PDF backgrounds are naturally difficult to see in both implementations. JPEG outputs remain visually comparable, and PNG output encodes the rendered pixels losslessly.

The standard and 450-DPI PDFs were opened in macOS Preview with `open -a Preview`; Preview's open file descriptors confirmed both documents were loaded. The side-by-side captures were rendered and inspected through independent PyMuPDF, not captured from Preview: this host does not grant external screen capture. PDFKit reopen assertions provide a second parsing implementation.

Native dialog cancellation runs in an actual bundled NSApplication. Export success uses the real app session and output pipeline. Synthetic clicks in Apple's separate Save-panel process were unreliable and are not reported as manual Save-button coverage. No user documents or accessibility permissions were needed.

## Performance and stress

`legacy-processing.json` and `native-processing.json` contain 10 raw samples per identical input/format/mode route, including transactional writes. The comparison uses explicit standard and 300/450/600 modes, not different UI defaults. Export acceptance is no repeatable median regression above 10%.

Some scan-at-600-DPI whole-matrix measurements varied near that threshold. `paired-scan-timings.json` therefore repeats all scan 450/600 PDF/JPG/PNG routes in 50 alternating pairs, with a persistent legacy worker, one warmup per route, and native release processing. These controlled pairs supersede noisy sequential scan results for the regression gate. All raw results, including slower observations, are retained.

`launch-ready-timings.json` measures external process launch to readiness markers in packaged release copies: native initial view layout/display in a visible main-capable window; legacy after original app construction and synchronous client updates. Eleven alternating trials retain the first launch separately. Repeated median: native 0.252 s, legacy 0.483 s. This is a readiness proxy, not measured hardware-input latency. `launch-window-timings.json` separately records uninstrumented process-to-visible-window timings.

UI preview measurements cover 10 changes each on text/vector, scanned and 10-page PDFs, including debounce and client/view update. Native p50 is about 162–166 ms and nearest-rank p95 166–170 ms, compared with legacy p50 509–512 ms and p95 510–626 ms. Core rendering-only preview timings are not substituted for UI responsiveness: the native preview renders more pixels and can take longer in isolation.

Peak RSS is process high-water memory, not per-operation incremental allocation. The release matrix uses approximately 108 MiB versus the reference's 761 MiB; exact observations are retained in JSON. `native-stress.json` records a 50-page, 600-DPI export, reopened with 50 pages and no text layer, at roughly 0.94 s on the synthetic 400×280-point pages. This does not predict A4/photo-heavy worst-case memory or speed. Rendering processes one page at a time. Rapid controls, file replacement, stale output rejection, write failure and subsequent recovery are exercised separately by session and transaction tests.

## Reproduction commands

```sh
scripts/test.sh
scripts/build-app.sh
PASSPORT_MEASURE_PREVIEW=1 scripts/smoke-test.sh
PASSPORT_BENCHMARK_OUTPUT=.build/benchmarks scripts/test.sh -c release --filter PerformanceTests
```

Historical reference and paired comparison helpers are intentionally temporary and removed after acceptance. To reconstruct the legacy baseline, use its recorded revision and dependency inventory in a separate checkout. Retained fixture hashes, raw reports and visual comparisons preserve the evidence without retaining a second app.

## Compatibility and final cleanup

[Acceptance CI run](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34149501070) passed native behavior tests, universal builds, packaged launch and window/export smoke on macOS 14.8.9 ARM and macOS 15.7.9 Intel. JSON runtime reports are retained beside this record. Earlier failed runs exposed and helped fix lazy PNG decoding and unreliable test-only panel automation. Final clean-checkout results follow after cleanup. Cross-compilation alone is not runtime evidence. Developer ID signing, notarization and a public release are outside this migration; the local app is ad-hoc signed.
