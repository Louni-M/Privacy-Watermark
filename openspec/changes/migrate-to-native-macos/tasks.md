## 1. Capture the reference and confirm build environments

- [x] 1.1 Record the legacy revision and run meaningful existing tests; document failures and known defects separately from behavior to preserve.
- [x] 1.2 Generate and retain the synthetic fixture corpus and reference export matrix described in design decision 7, including transparency, EXIF orientation, PDF annotations/links, rotations, and page boxes.
- [ ] 1.3 Build the current Python app and capture launch, preview, export, and memory baselines using the repeatable same-machine protocol, with explicit mode/DPI settings and raw timings.
- [x] 1.4 Verify the Swift/macOS SDK toolchain and identify environments for Apple Silicon, Intel, and macOS 14 runtime checks; record unavailable checks as pending prerequisites.

## 2. Establish the native foundation and prove export parity

- [x] 2.1 Create the Swift package with macOS 14 deployment, processing library, SwiftUI executable, and native tests; verify the skeleton builds for arm64 and x86_64.
- [x] 2.2 Add reproducible universal app bundling with the current name/icon, bundle metadata, resource copying, and ad-hoc signing; smoke-test local bundle launch.
- [x] 2.3 Implement validated immutable document loading with the existing extension, 100-MiB, 50-page, 20,000-pixel, corrupt-file, and protected-PDF rules; test exact boundaries and readable error categories.
- [ ] 2.4 Implement the shared native watermark renderer and pixel/PDF-point/DPI coordinate adapters; test directions, colors, parameter boundaries, empty text, and zero opacity against reference images.
- [x] 2.5 Implement image-to-JPG/PNG/PDF export with verified encoding, dimensions, visual quality, opaque conversion, orientation handling, and removal of source image metadata.
- [x] 2.6 Prove standard PDF export preserves source and watermark text extraction, vector rendering, page geometry, visible annotations/form appearances, and existing links after saving and reopening; resolve native API issues before UI completion.
- [x] 2.7 Implement flattened PDF export at 300/450/600 DPI with page-at-a-time rendering; verify image resolution, stable watermark proportions, no embedded source/watermark text layer, and bounded memory behavior.
- [ ] 2.8 Implement PDF-to-JPG/PNG page-series exports with current 72-DPI output sizing, page order/naming, both processing modes, and clean image metadata; compare all routes with references.

## 3. Build the simplified native workflow

- [x] 3.1 Implement the single-window SwiftUI layout with Open, document information, watermark text, preview, export, and collapsed appearance adjustments using native system appearance.
- [x] 3.2 Implement session settings, format-dependent choices, initial flattened/450-DPI PDF mode, selectable-text alternative, and accurate mode explanations; verify existing defaults and ranges otherwise remain intact.
- [ ] 3.3 Implement native input/save/folder panels and the current default filenames; verify dialog cancellation, one-document replacement, and successful export feedback.
- [x] 3.4 Connect background first-page/image preview with reduced-resolution rendering, debouncing, generation checks, and immutable parameter snapshots; verify rapid changes and document replacement never publish stale previews.
- [x] 3.5 Connect independent full-quality export from source snapshots, busy state, and error recovery; verify format changes cannot export stale preview bytes and repeated exports do not accumulate watermarks.
- [x] 3.6 Implement source-path/identity protection, destination conflict handling, staged writes, and temporary-file cleanup; test individual and page-series write failures without damaging originals or pre-existing destinations.
- [ ] 3.7 Preserve private diagnostic behavior with no document contents or watermark text in logs; verify offline use and recoverability after validation, preview, or export failure.

## 4. Complete acceptance before removing the reference

- [ ] 4.1 Run native behavior tests for the full format matrix, modes/DPIs, controls, metadata, limits, recovery, repeated exports, and source preservation; map each specification requirement to evidence.
- [ ] 4.2 Review representative native/reference outputs side by side and reopen them in Preview and an independent PDF reader/parser; confirm accepted font differences do not hide readability, geometry, or text-layer regressions.
- [ ] 4.3 Measure native release launch, preview p50/p95, export medians, and peak memory against the recorded baseline; demonstrate improvement beyond timing noise and resolve repeatable export slowdowns exceeding 10%.
- [ ] 4.4 Exercise the 50-page/high-DPI stress case and rapid-control/file-switch workflows; record responsiveness, memory, and failure/recovery outcomes separately from routine quick tests.
- [ ] 4.5 Build both architecture slices and run native install/open/preview/export smoke checks on Apple Silicon, Intel, and macOS 14 environments; record actual runtime coverage without equating cross-compilation with execution.
- [ ] 4.6 Complete the acceptance record with commands, fixture identities, raw measurements, visual findings, and compatibility results; keep this gate open until every required check passes.

## 5. Retire Python and finish the repository cleanup

- [ ] 5.1 After section 4 passes, remove `main.py`, `app.py`, `watermark.py`, `pdf_processing.py`, `utils.py`, `constants.py`, `requirements.txt`, `requirements-dev.txt`, and `Passport Filigrane.spec`.
- [ ] 5.2 Remove obsolete pytest/Flet tests and temporary comparison/prototype code; retain useful synthetic fixtures, native behavioral tests, baseline results, and version history without an in-repository legacy app copy.
- [ ] 5.3 Replace Linux/Python CI with macOS native tests and app build checks, including architecture coverage where runners support it; remove stale dependency setup and Python-only coverage artifacts.
- [ ] 5.4 Update README, security documentation, relevant ignore rules, and stale UI illustrations for the native app, supported systems, flattened default, accurate privacy limits, build/test commands, and actual signing status.
- [ ] 5.5 Build, test, and smoke-test the final universal app from a clean source checkout without Python dependencies; audit sources, active docs, CI, temporary artifacts, and bundle contents for leftover legacy dependencies before marking the migration complete.
