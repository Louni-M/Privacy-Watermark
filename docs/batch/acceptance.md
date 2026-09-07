# Batch implementation evidence

Status: local implementation and verification passed. Required manual Add-file selection, Finder drag-and-drop and keyboard interaction evidence remains pending; this change is not ready to archive.

## Environment and baseline

Recorded 2026-09-07 on Apple M3, 16 GiB RAM, macOS 26.6.2 (25G83), Swift 6.3.3 Command Line Tools. Workload windows use a 2× display backing scale. Baseline application revision: aff93f4364a985030c2fb5f7e2c70ecb9979f1c3. Existing uncommitted OpenSpec planning/archive changes were preserved.

Before application edits, scripts/test.sh exited 0 (20 tests reported, opt-in benchmarks/interface capture skipped). baseline-tests.txt retains the log. The expected corrupt-PDF fixture emits a CoreGraphics diagnostic; no assertion failed. baseline-benchmark.txt, baseline-processing.json and baseline-stress.json retain release measurements of the existing export routes and 50-page/600-DPI workload. baseline-fixture-hashes.txt identifies the synthetic inputs. No concurrent builds or benchmarks ran during measurement.

During implementation, the first settings mutation guard recursively entered the Observation-generated setter and crashed. It was replaced with a guard before stored-state mutation; the retained snapshot/mutation-guard regression test passes. export-session-diagnosis.txt records the failed run separately from current verification. Compilation diagnostics encountered while wiring new APIs were corrected, not treated as preserved behavior.

## Requirement-to-evidence mapping

| Requirement | Implementation and evidence |
|---|---|
| Ordered mixed batch, defaults and identity | BatchCollection, OutputPolicy, BatchContractTests, BatchExportTests, SessionTests; same-name distinct paths, content-identical files, symlinks/hardlinks, append/removal/Clear, invalid rows, selection and shared settings |
| Progressive validation and source consistency | SourceValidation, serialized validation worker, value-only row metadata and SHA-256 fingerprints; changed/deleted/unreadable files, re-addition recovery and pending-removal tests; existing exact byte/dimension/page limits retained |
| Page/viewport preview correctness | PagePreviewTests, ViewportTests; invalid page bounds, first/middle/last geometry, byte-identical full PNG page-image previews, pixel-identical uncompressed panned crops and output-resolution/buffer bounds |
| Stale request rejection and bounded ownership | PreviewWorkerTests, rapid selection/page/settings/zoom tests; full request keys, cancellation, one retained preview source, obsolete-revision eviction, 96-MiB cache accounting including decoded pixel cost |
| Preview remains independent of export | previewCompletesWhileExportWorkerIsBlocked holds export at a page boundary while another file's preview completes; structured cancellation handles, serialized validation and sequential export |
| Safe destinations and publication | DestinationAllocator, BatchExportTests; filesystem case/Unicode collisions, reservations, existing files/directories, batch-source protection, late collisions and reruns; exclusive rename publishes a complete file or page folder |
| Run snapshots, failure isolation and cancellation | Core and session tests cover immutable settings, mutation/overlap guards, invalid-row exclusion, per-file failure, all-invalid/all-success/mixed summaries, before-work/mid-page/pre-publication/post-publication cancellation and subsequent recovery |
| Native controls and feedback | Real NSApplication window smoke: Add/folder panel cancellation, mixed import, row errors, selection/removal, page navigation, zoom/viewport/Fit, shared controls, exports, cancellation and summaries; normal/minimum-size captures inspected |
| Complete conversion matrix and retained behavior | BatchMatrixTests exercises four policies × standard/300/450/600 modes across JPG, oriented JPG, opaque/transparent PNG and PDF; retained DocumentTests cover encodings, EXIF/GPS stripping, geometry, standard text/annotations/forms/links, all DPIs, exact limits and source preservation |
| Saved-output visual review | visual/ retains output PDFs/PNGs, fit previews, detailed panned previews and comparison sheets; first/middle/last pages, rotated/cropped geometry, annotations, both directions, black/gray and transparent image behavior |
| Large-batch responsiveness and memory | measurement-10.json, measurement-100.json, workload-summary.json; native-generated corpus with hashes/geometry, raw UI/preview/import/export/cancellation timings and process peak RSS |
| Export route regression and stress | route-comparison.json, paired-scan-comparison.json, current-stress.json; full release matrix and controlled follow-up on initially flagged routes; cancellation before page index 25 of a 50-page 600-DPI PDF |
| Supported architectures and clean checkout | Universal build and fresh source snapshot checks recorded below; actual macOS 14 ARM and macOS 15 Intel runtime CI passed at e30389c70e8ed4904c1b62f2483f6740f142702c |

## Corpus and reproduction

BatchCorpusTests generates 40 JPG/JPEG, 30 PNG and 30 PDF inputs. Six images are 4000×3000 pixels. Copies of retained synthetic PDFs preserve text/vector, scan, annotation, rotation/crop and varied page-count cases. Content-identical copies remain distinct filesystem inputs. Invalid and boundary fixtures stay separate.

corpus-manifest.json records ordered names, content hashes, filesystem identities and geometry. Its ten-file subset contains four JPEG, three PNG and three PDF inputs, including the same largest image/page as the full corpus. Two independent generations had identical bytes on this host; inode/device values naturally vary by generation. There is no hard 100-file application cap.

~~~sh
scripts/test.sh
PASSPORT_CORPUS_OUTPUT=.build/batch-corpus scripts/test.sh -c release --filter BatchCorpusTests
PASSPORT_VISUAL_OUTPUT=.build/batch-visual scripts/test.sh --filter VisualReviewTests
PASSPORT_BENCHMARK_OUTPUT=.build/batch-current scripts/test.sh -c release --filter PerformanceTests
PASSPORT_BATCH_CORPUS="$PWD/.build/batch-corpus" PASSPORT_BATCH_COUNT=10 PASSPORT_SMOKE_OUTPUT=.build/measure-10 scripts/smoke-test.sh
PASSPORT_BATCH_CORPUS="$PWD/.build/batch-corpus" PASSPORT_BATCH_COUNT=100 PASSPORT_SMOKE_OUTPUT=.build/measure-100 scripts/smoke-test.sh
scripts/build-app.sh
scripts/smoke-test.sh
~~~

Choose an unused corpus destination: generation deliberately refuses to overwrite files. Run timed workloads sequentially with no simultaneous build or benchmark.

## Visual and window findings

Comparison-sheet columns are saved output, full-page Fit preview, and detailed zoomed/panned preview. Original geometry and watermark origin remain consistent while zoom/panning changes the displayed region. Text/vector, annotation and form content remains visible in standard output; flattened and page-image modes retain their raster-opacity behavior. Detailed previews retain available output detail. JPEG and raster antialiasing differences are visible at edges; no displaced watermark pattern, incorrect page, altered page geometry or transparent-image compositing regression was found in the reviewed samples. Fit previews may approximate compression, as specified.

The standard and flattened rotated/cropped two-page PDFs and flattened ten-page PDF were opened with macOS Preview. Its open-file descriptors confirmed all three were loaded. PDFKit independently reopens every PDF produced by the matrix. The comparison images are generated test renders, not screenshots from Preview.

Window smoke runs in a real native window, and panel cancellation calls the real native panel. Import/navigation/settings/removal/pan/export actions are programmatic. They are not evidence that a human used the Add panel or physically dragged files from Finder. Manual mixed drag-and-drop, keyboard interaction and Add-panel multi-selection remain pending. Window captures at 1040×720 and 860×600 were inspected; a capture readability issue in the Clear button was corrected.

## Performance interpretation

Reports retain first/cold observations separately from repeated measurements. Selected-preview timing includes debounce, source consistency checking, rendering, layout/display and 10-ms polling. UI acknowledgement includes synchronous layout/display; it is a programmatic proxy, not measured physical input latency. RSS is process high-water memory, not an incremental allocation measurement. Ten-file and hundred-file runs use separate release processes.

The full per-route comparison excludes each first observation from the repeated median. Two standard scan routes initially exceeded 10%. An isolated baseline revision and current release core were then measured in ten alternating-order process pairs, each with one first observation and 50 repeated samples per route. Median-of-process-medians ratios were 0.996 for PDF and 1.007 for PNG. The slowdown did not repeat; these controlled measurements supersede the two noisy full-matrix comparisons. All observations are retained.

The 50-page/600-DPI export completed in approximately 0.71 s on 400×280-point synthetic pages. Cancellation injected before page index 25 discarded the unfinished source, saved zero files and completed cleanup approximately 1.6 ms after the cancellation boundary. This is core boundary timing, separate from native UI cancellation acknowledgement. It does not predict arbitrary large-page decoder latency.

## Finalization and pending checks

No GitHub distribution, release packaging workflow, signing/notarization or installation wizard was added. Existing ARM/macOS 14 and Intel CI coverage is preserved. Local cross-compilation is not runtime CI evidence.

The native migration was synced and archived before this batch change. When finalizing, synchronize/archive this batch delta after its required acceptance passes. Do not re-sync the historical migration over these new batch contracts.

## Final local results

The final workload observations, including ten cancellation acknowledgements per workload, all meet the design budgets:

| Files | Selection p95 | Fit preview p95 | Cancel acknowledgement p95 | Import | Export | Peak RSS |
|---|---|---|---|---|---|---|
| 10 | 13.6 ms | 218.9 ms | 21.7 ms | 0.43 s | 1.18 s | 386.2 MiB |
| 100 | 13.1 ms | 203.7 ms | 23.3 ms | 1.23 s | 5.81 s | 390.4 MiB |

Memory allowance: 836.3 MiB. Both sizes pass selection/cancel ≤100 ms and Fit preview ≤500 ms. These synthetic-workload observations are not guarantees for every permitted input.

The local universal build and built-bundle launch passed. A fresh native source snapshot without an inherited build cache also passed the behavior suite, both architecture builds, ad-hoc signature verification, built-app launch and native window/export smoke. See universal-build.txt, final-bundle-launch.json, final-smoke.json, clean-tests.txt, clean-build.txt and clean-smoke.txt. Native source hashes identify that snapshot. The original working branch and pre-existing planning/archive edits were not changed by the isolated CI branch.

The first CI attempt exposed a Swift 6.0 Testing-macro incompatibility in one assertion (a throwing expression on its right-hand side). Reading the saved bytes before the assertion fixes compatibility without changing the comparison. The application compiled in that job. ci-first-arm.txt preserves the failed diagnostic; the final CI run passed after this fix.

Measurement source reference: per-route rendering/export timings correspond to implementation commit 53c1a0de1a44af9b43834ebb773ae712736d04a9. Final workload measurements and clean-source verification use e30389c70e8ed4904c1b62f2483f6740f142702c, including the Swift 6.0 test fix, Fit zoom bounds and checking queued fingerprints before decoding corrupt replacement content. Rendering/export routes remain unchanged. Previous workload observations are retained as measurement-before-source-check-10.json and measurement-before-source-check-100.json.

## Final runtime CI

[CI run 34161507973](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34161507973) passed on macOS 14 Apple Silicon and macOS 15 Intel at e30389c70e8ed4904c1b62f2483f6740f142702c. Both fresh runner checkouts passed native behavior tests (including real interface capture), universal ARM/Intel builds and signature checks, built-app launch, and native window/panel/export smoke. Runtime and step results are retained in ci-run.json, macos-14-smoke.json, macos-14-bundle-launch.json, macos-15-intel-smoke.json and macos-15-intel-bundle-launch.json. The isolated verification branch is codex/add-batch-watermarking; no PR, merge or release was created.

Overall progress: 25/26 tasks complete. Task 6.2 remains open for the requested manual interaction report. Programmatic window evidence is complete and is not substituted for that report.
