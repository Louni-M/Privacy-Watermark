## Context

See `proposal.md` for motivation and the three capability specs for the behavior contract. The current app has a small Python engine, a Flet window, and pytest coverage; there is no persisted user database or settings migration. Preview uses a 500 ms timer and cached output bytes. Standard PDF export mutates the loaded document; image format selection can leave cached bytes out of date. These are defects to eliminate, not parity requirements.

Inspected environment: Apple Silicon, macOS 26.6.2, Swift 6.3.3, and Command Line Tools selected. Full Xcode is not the selected developer directory. Existing distribution is a downloadable app without Developer ID signing; CI currently runs Python tests on Linux. Existing assets include an `.icns` icon and two illustrative screenshots. Synthetic tests provide references; user identity documents are unnecessary.

## Goals / Non-Goals

**Goals:** A small native architecture with one rendering model, immutable source input, bounded background work, reproducible app packaging, and evidence-based removal of the legacy implementation.

**Non-Goals:** No framework for multiple platforms, Python bridge, plugin system, database, presets, batch processing, PDF editing, password entry, extra input formats, page browser, updater, App Store distribution, or permanent second implementation. The current empty-state copy mentions drag-and-drop but has no implemented drop handler; retain native Open and do not advertise unsupported dropping. Code cleanup covers this app's legacy stack, not unrelated tooling or user files.

## Decisions

### 1. SwiftUI application with a small native processing module

Use SwiftUI for the window and controls, AppKit for native panels and application integration, PDFKit for document inspection, and Core Graphics/Core Text/ImageIO for rendering and encoding. Use an observable main-thread session model holding the loaded source identity, watermark values, export choice, preview, and operation state. Keep processing in a separate Swift target with native unit/integration tests. No third-party runtime packages are planned.

SwiftUI's modern observation support is available from macOS 14, matching the agreed deployment target ([Apple documentation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)). A Python backend with SwiftUI would retain the packaging burden; a full AppKit UI would add manual view wiring without a current need.

### 2. One package and a small app-bundling script

Use Swift Package Manager with a processing library, executable UI target, and tests. Declare macOS 14 as the minimum and use a Swift 6 toolchain, recording the tested version in build instructions. A small macOS build script creates the `.app` structure with `Info.plist`, executable, and existing icon, then assembles a universal arm64/x86_64 release and applies ad-hoc signing for local execution. Verify bundled resources and architecture slices. The package is the build source of truth; do not maintain parallel Xcode and package configurations. Swift packages support executable products and deployment constraints ([Swift PackageDescription](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)).

This uses the locally available toolchain and keeps packaging explicit. An Xcode app project remains unnecessary for this scope. Developer ID signing/notarization and public publishing are not prerequisites for building and reviewing the app; documentation must not imply an ad-hoc build is notarized. Full Xcode or another test machine may be needed for automated UI or older-OS runtime evidence; verify this at the beginning of implementation and record any unavailable checks.

### 3. Compact interface with explicit export consequences

Use a single window with Open, file information, watermark text, large preview, and export controls. Put opacity, size, spacing, color, and direction in a disclosure section. Keep PDF mode understandable at export time, with quality adjacent when relevant. Use native system appearance and controls instead of recreating the fixed custom dark palette. Keep English labels and current app identity.

Retain the setting ranges and initial values specified in `native-watermark-workflow`, except the explicitly approved flattened/450-DPI initial PDF mode. Preserve session settings across file replacement but not application restart. Preserve image→JPG and PDF→PDF format defaults. No persistent state system is needed.

### 4. Immutable inputs and a common watermark renderer

Retain validated source bytes or an immutable source snapshot for the active document. Decode image input once into an immutable CGImage snapshot; preview/export reuses it without re-decoding the file. Every preview or export constructs operation-local document objects and captures a value snapshot of current parameters. Never mutate a shared PDFDocument and never export cached preview bytes. This prevents repeated watermark accumulation and stale format output.

Use one watermark layout implementation with coordinate adapters: pixels for image input and PDF points for PDFs. Scale the PDF layout by DPI/72 for flattened output so watermark size and density do not change with quality. Use a native Helvetica-compatible system font and Core Text glyph rendering. Retain full diagonal tiling, including coverage at page edges. Differences in glyph metrics and antialiasing are accepted; changing the apparent opacity or scale substantially is not.

Use opaque output for images to match current behavior. Capture a transparent PNG reference before choosing the exact background/compositing treatment so native conversion does not silently alter visible content. Apply orientation consistently and include EXIF orientation fixtures; privacy cleanup must not create sideways exports.

### 5. Native export routes, proved before the full interface

Core Graphics contexts can target bitmaps and PDFs ([Apple CGContext documentation](https://developer.apple.com/documentation/coregraphics/cgcontext)). Build a small end-to-end processing slice first:

| Input / destination | Approach and parity obligation |
| --- | --- |
| Image → JPG/PNG | Decode, render pixels with watermark, encode a fresh image with an explicit safe property set. Preserve dimensions; use lossless PNG and a JPEG quality calibrated against existing quality 90. |
| Image → PDF | Encode the rendered image once and embed its JPEG bytes into one PDF page sized to its pixel dimensions in points. |
| PDF → standard PDF | Draw original page vector content into a new PDF graphics context, then draw watermark text as vector text. Apply page-box and rotation transforms explicitly and preserve visible annotation/form appearances. Verify original and watermark text extraction after save/reopen; no whole-page bitmap fallback is allowed. |
| PDF → flattened PDF | Render one page at selected DPI, combine the watermark in pixels, encode with quality comparable to existing 95, and embed into a fresh page of matching displayed dimensions. Embed the encoded JPEG bytes directly, without decoding them again. Do not copy source text or annotation layers. |
| PDF → JPG/PNG pages | Preserve existing 72-DPI output sizing and naming. Standard and flattened settings currently affect intermediate appearance; compare both routes against references, including the high-resolution flatten-then-downsample case. Do not silently reinterpret selected DPI as page-image export resolution. |

Source PDF interactivity requires care: redrawing a page alone may discard links or annotations. The early slice must check visible annotations, form appearances, links, crop boxes, and rotation against the current engine; preserve existing standard-mode behavior using native PDF APIs as needed. Do not replace this with a new PDF editing feature or silently ship known content loss. If a native API fails the contract, resolve the implementation before proceeding to cleanup.

Implementation measurements found that drawing a compressed page image into a PDF CGContext adds another JPEG decode (about 24 ms for the synthetic 600-DPI scan). Image and flattened PDF output therefore use a narrow streaming Swift writer for the fixed one-RGB-JPEG-per-page structure; standard PDF composition stays in Core Graphics. The writer handles no arbitrary PDF parsing or editing. Reopen tests and independent image/text inspection verify its page tree, streams, cross-reference offsets, dimensions, and lack of selectable text.

Use ImageIO to encode new destinations from rendered pixels rather than copying source properties. Image destinations expose explicit image/property writing and finalization ([Apple ImageIO documentation](https://developer.apple.com/documentation/imageio/cgimagedestination)). Verify actual metadata in outputs. Standard PDF export is not promised to sanitize all PDF metadata. Avoid claiming resistance to every watermark-removal technique or OCR.

### 6. Background work and safe destinations

Run rendering off the main actor, with a serial processing owner so non-thread-safe document objects do not cross concurrent operations. Debounce appearance changes briefly (initial tuning target 100–150 ms), cancel superseded work where possible, and attach a generation ID so stale completions are ignored. Render previews at display-appropriate resolution; export independently at required resolution. Disable conflicting export actions while preserving a responsive window.

Validate file size before reading, dimensions before full image decode where possible, and PDF count/protection before page rendering. Use native BGRA bitmap storage to avoid unnecessary channel conversion. For pages without annotations, draw the CGPDFPage with its crop/rotation transform directly; use PDFKit drawing when annotation appearances are needed. Render and release one high-DPI page at a time; use checked size calculations and handle allocation failure instead of adding an arbitrary lower product limit.

Native save panels open in the source folder, retain the existing export basename, and handle individual file replacement confirmation. Present panels as sheets when a main window is available. For a page series, preflight destination names and obtain a single conflict confirmation if needed. Reject destinations resolving to the input file, including aliases through filesystem identity where practical. Stage outputs beside their destination and finalize only after successful rendering; retain pre-existing outputs until replacement succeeds and clean only temporary files created by the operation. This is necessary for the agreed preservation-of-originals standard.

### 7. Evidence defines completion

Before changing processing, record the current revision, run existing meaningful tests, generate non-sensitive fixtures/reference exports, and build the Python reference app. Preserve reference data and measurements after removing comparison code. Translate behavioral tests, not Flet widget structure assertions or implementation-specific mocks.

The comparison corpus includes a passport-like photo, opaque and transparent PNGs, an EXIF/GPS-bearing image, a selectable-text/vector PDF, a scanned PDF, mixed sizes/rotations/crop boxes, visible annotations and links, a 10-page document, and a 50-page stress fixture. Exercise corrupt, protected, zero-page, unsupported, and boundary inputs; repeated exports; rapid changes; cancelled dialogs; and write failures. Full 600-DPI stress evidence is recorded separately from routine quick tests. Inspect outputs in Preview as well as programmatically; use a temporary independent PDF parser during migration to corroborate text/layer claims, then remove that tooling.

Performance protocol: use release bundles on this Mac, identical fixtures and explicit settings, and alternate implementations to reduce ordering effects. Record a first-launch observation separately from at least 10 repeat launches. Measure launch-to-interactive, last-control-change-to-correct-preview, and export-request-to-complete-files. Measure both preview p50 and p95; record export timings per format/mode at every PDF DPI and observe peak memory. Store raw timings and medians. Launch and preview improvement must exceed measured run-to-run noise; do not invent a speedup factor. Define a material export regression as a repeatable median slowdown exceeding 10% for a representative route; investigate noisy results with additional runs. This 10% threshold and protocol are engineering operationalizations of the user's agreed completion standard.

Compatibility evidence includes both architecture builds, native runtime smoke checks on Apple Silicon and Intel, and macOS 14 runtime coverage. CI runner availability must be inspected during implementation; cross-compilation on the current Mac alone does not satisfy runtime verification. Missing evidence remains an explicit unfinished task.

## Risks / Trade-offs

- Native PDF compositing can change text extraction, annotations, and page geometry → prove these with saved/reopened outputs before investing in the complete UI.
- Flattened 450-DPI defaults increase output size and processing cost → compare identical modes, retain standard mode and all DPI options, and make the consequence visible.
- Native encoders and fonts differ from Pillow/MuPDF → calibrate visible quality with reference fixtures rather than requiring byte equality or identical codec quality numbers.
- High-DPI documents can consume substantial memory even within current input limits → process pages serially, release buffers, measure peak memory, and fail gracefully.
- Minimum-OS and Intel runtime validation are unavailable on the current host alone → arrange suitable CI/test environments early and do not mark cross-builds as runtime verification.
- A universal ad-hoc app is not a notarized public release → preserve the current local/downloadable distribution scope and state signing status accurately.
- Retaining both stacks can become permanent → place legacy deletion after acceptance as a required task in this change, with a final dependency and documentation audit.

## Migration Plan

1. Capture the legacy behavior, revision, fixtures, and performance baseline before deleting anything; keep temporary comparison work isolated from the final native structure.
2. Establish native build/test/bundle tooling and prove standard PDF, flattened PDF, image output, geometry, and metadata behavior in a small processing slice.
3. Implement the native session/window and complete export/recovery behavior. Run the parity, visual, compatibility, and performance gates; fix regressions while the reference remains available.
4. Once acceptance passes, remove legacy application modules, requirements, PyInstaller configuration, obsolete pytest files, and temporary comparison/prototype tooling. Preserve useful fixture data, native tests, baseline results, icon, and git history. Do not touch pre-existing unrelated `.agents` or OpenSpec configuration.
5. Make macOS native CI and documentation authoritative, remove stale screenshots or replace them if they misrepresent the new interface, build/test from a clean checkout without Python dependencies, and audit the universal bundle.

Before acceptance, the Python app remains the fallback. After cleanup, version history and existing release artifacts provide rollback; no second maintained runtime or in-repository legacy copy is retained. Creating or publishing a public release is separate from this planning change's implementation work.
