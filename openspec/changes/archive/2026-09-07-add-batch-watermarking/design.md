## Context

See `proposal.md` for the outcome and scope. `Session` currently owns one immutable `SourceDocument`, one preview and shared settings. `SourceDocument.load` retains source bytes and decoded image pixels; copying this ownership model into every batch row could consume gigabytes. `Processing.preview` hardcodes PDF page zero and caps PDF scale at 2. Export already renders independently of preview bytes and stages outputs with `OutputTransaction`; its replacement path is unsuitable for the new no-overwrite batch policy. The existing native corpus and ARM/macOS 14 plus Intel CI runs provide the regression baseline.

The migration's three specs were synced into `openspec/specs` while preparing this proposal. The completed migration is now archived at `openspec/changes/archive/2026-09-07-migrate-to-native-macos`. This proposal modifies existing workflow/export contracts and adds batch orchestration; implementation has not started.

## Goals / Non-Goals

**Goals:** extend the native processing core, bound memory by active operations, make export completion unambiguous, and turn every accepted interaction into observable test evidence.

**Non-Goals:** no second rendering engine, database, background service, automatic parallel export farm, permanent document copies, or per-item setting inheritance. Broader product exclusions are in the proposal. Existing pixel/PDF-point watermark sizing, alpha handling and standard/flattened semantics remain authoritative.

## Decisions

### 1. An ordered batch with one selected item and one shared configuration

Introduce batch rows with a stable ID, source URL, filesystem identity, validation metadata/content fingerprint, and independent validation/export state. Keep preview selection separate from row status. States distinguish checking, ready/invalid, pending, exporting, saved, failed and unprocessed after cancellation; do not use one Boolean for both import and export.

Keep received addition order and export in that order. The first candidate is selected when the list was empty; later additions preserve selection. Selecting a file resets page to zero and view to Fit; removing selection chooses the following row, otherwise the preceding row. Clear all retains shared settings, matching ordinary session behavior. File icons and labels suffice; an eagerly rendered thumbnail gallery is unnecessary.

Resolve duplicate identity before queueing expensive validation. Prefer resolved filesystem identity (including hard links); use canonical URL fallback when identity is unavailable. Never deduplicate by basename or content hash. Hashes have a separate role in source consistency. Invalid entries remain visible and removable. Unsupported directories/non-file drops receive concise feedback without recursive import. Arbitrary row reordering is not added.

Alternative: independent per-row sessions would duplicate state and introduce unrequested settings overrides. A single shared configuration matches the agreed workflow.

### 2. Validate progressively and retain only active full documents

Validate candidates off the main actor, one at a time, publishing row results incrementally. Retain metadata and a SHA-256 fingerprint of validated bytes, then release decoded data for inactive rows. Reuse the current full validation path first; optimize metadata probing only if it still proves the existing readability checks. Keep at most the selected preview's full source and the current background operation's source, rather than an unbounded document cache. Import, preview and export work must have explicit ownership and cancellation.

On reloading an inactive source, verify identity and fingerprint before presenting it or exporting it. A changed/missing item receives a “Remove and add this file again” or unavailable error; never silently substitute new bytes for a reviewed item. Check for changes across the read itself. This preserves preview/export consistency without copying every private source to a session cache on disk. Current operations use their immutable loaded bytes.

Add and remove remain available during validation; generation/item identity checks discard completion for removed items. Export waits for pending validation to finish and requires at least one valid item. State counts make that wait visible. Shared controls and collection mutations are disabled during export; selection, page browsing, view controls and Cancel remain usable.

Alternative: retaining 100 decoded sources is simple but fails the memory goal; a permanent source staging cache introduces privacy and cleanup work that this feature does not need.

### 3. Make preview an explicit page-and-view request

Extend the shared preview boundary to include item identity, validated source fingerprint, PDF page index, watermark/settings revision, effective output policy, view scale and viewport. Invalid page indices must fail safely. Debounce appearance changes using the existing approach, cancel obsolete work, and only publish a result with a matching full request key. Do not show the previous item's image beneath a newly selected filename while loading. Within one item, a retained preview during updates must be visibly marked as updating.

Use the existing render/encoding rules for the effective output: standard PDF preview uses vector-mode opacity, flattened PDF uses the selected raster mode, and PDF-to-image preview represents the final 72-DPI page image rather than promising high-resolution output. A fitted preview may be cheaper; detailed preview must resolve available source/output detail and preserve geometry and watermark proportions. JPEG compression differences may be approximated in fit view, but detailed comparison must use an equivalent export rendering path. Export never consumes preview bytes.

Implement a scrollable preview host with Fit, zoom-in/out, and a displayed scale. Use 25–400% as the initial explicit zoom range, plus Fit; 100% maps PDF points or image output pixels to logical view points, accounting for display backing scale when rendering. Changing PDF page preserves Fit/manual zoom and resets scroll position. Zoom never changes watermark settings or output dimensions. Disable page arrows at boundaries and hide them for images.

Bound preview cache to 96 MiB, keyed by the full request, and clear obsolete revisions. Cap a rendered preview buffer at 16 megapixels. When a requested zoom would exceed that buffer, render only the visible region with the original document coordinate origin preserved; do not merely enlarge a low-resolution image. One viewport buffer is sufficient; a general tiled-document framework is unnecessary. For image outputs, never imply detail beyond their real pixel dimensions.

Schedule visible preview work separately from sequential export so selecting a file can still finish while a long PDF exports. Limit concurrent full-document ownership to these active workers and avoid eagerly previewing all batch entries. Verify scheduling and cancellation rather than assuming actor isolation alone makes long synchronous work interruptible.

### 4. Resolve output policy centrally and publish without replacement

Add a batch-level Keep original format/PDF/JPG/PNG policy that resolves to the existing `ExportSettings` for each input. Keep original maps `.jpeg` to `.jpg` encoding/extension; source stems remain intact. Show shared PDF mode/quality when any batch item is a PDF, regardless of which row is selected. Preserve flattened 450 DPI at startup. One-item and many-item exports use the same folder workflow.

Allocate names in input order, considering all source identities, files/directories already present and names reserved by this run. Use `<stem>_watermarked.ext`, followed by `<stem>_watermarked (2).ext` etc. Page-image folders use the same suffix convention; contained names preserve the existing `<stem>_page_NNN` pattern. Treat case/Unicode collisions according to the destination filesystem, not only a case-sensitive in-memory set. Render into private staging beside the destination and publish only complete input outputs. Use no-replacement filesystem operations; an existence check alone is not sufficient. If another process wins a name, choose the next suffix without overwriting or re-rendering already prepared output.

For page series, render the entire series in a new private folder, then publish that folder as one unit. The existing core transaction can be reused inside that isolated folder, but it must never merge into a user's existing folder. A single-file output follows the same staged publication principle. Protect every batch source, not just the current input. Remove empty/partial staging on normal failure or cancellation.

Alternative: asking about every replacement would interrupt unattended batches, and an all-batch transaction would contradict keeping completed copies after cancellation.

### 5. One cancellable run, committed per source document

Capture eligible row IDs, verified sources, shared settings and output policy at run start; store URLs/fingerprints and load each source just before processing, not all decoded documents. Keep a structured task handle whose cancellation reaches core loops. Check cancellation before each input, between PDF pages/encoding stages, and immediately before publication. If a synchronous decoder is running, acknowledge “Cancelling…” immediately and wait for the next safe boundary. Do not promise forced interruption inside system decoding.

Treat publication as the completion boundary: before it, discard the current input on cancellation; after it, record saved and retain output. A page series has one publication boundary. Increment source-document progress after a success/failure; invalid import rows are visibly excluded from the run denominator but included in the final overall failure explanation. End summary lists saved, failed and not processed; identify per-file messages without logging private content.

Continue after individual read/render/write failures, checking cancellation separately from errors. Release the source after each input. After finishing, editing/re-adding items and another Export all run are possible. A rerun attempts eligible files anew and uses new numbered names; selective retry/export and resumable jobs are not added. A failed row's export status is not a permanent validation failure unless its source is now invalid.

### 6. Evidence and engineering budgets

Retain native regression coverage for encodings, dimensions, EXIF/GPS removal, standard text/vector/annotation/link behavior, all flattening DPIs, source immutability and exact limits. Add behavioral tests for the batch state machine and output allocator, including filesystem collisions appearing after preflight. Exercise cancellation before work, within a multipage PDF, immediately before publication and after publication; a test hook at boundaries is preferable to timing-dependent sleeps.

Use deterministic native-generated synthetic files. The 100-file corpus contains 40 JPG/JPEG, 30 PNG (opaque and transparent) and 30 PDF files (text/vector, scanned, rotated/cropped, annotations, and varied page counts). Include several 12-megapixel images; content-identical files at distinct paths count as distinct inputs. Keep a 10-file subset with the same largest image/page to compare memory. Add corrupt/protected/over-limit files separately and exercise a 50-page, 600-DPI document as a stress case. Reuse useful existing fixtures; no private samples are required.

Record release-mode first/cold observations separately, then 10 timed selected-preview changes on the same local Mac, with hardware, OS, display scale, file hashes, output policy and DPI recorded. Engineering acceptance targets for the representative corpus: UI selection/cancel state acknowledgement p95 at most 100 ms; normal Fit preview after a settled change p95 at most 500 ms; the 100-item batch's peak RSS no more than twice the 10-item subset plus 64 MiB. These are implementation test budgets, not universal timing guarantees for every permitted 100-MiB input. Report import time, total export time, per-input medians, peak memory and cancellation completion separately. On unchanged individual export routes, investigate and fix repeatable release median regressions above 10% against the current native implementation. Run measurements without simultaneous builds/benchmarks.

Visual review must compare selected first/middle/last pages, rotated/cropped geometry, both directions/colors, transparency and fit/zoom previews with saved output in standard/flattened and page-image modes. Include real window exercise of Add files cancellation, mixed drag-and-drop, selection/removal, shared controls, navigation/zoom, progress and Cancel. Retain ARM macOS 14 and Intel native CI build/test/smoke coverage; distinguish programmatic panel cancellation from manual selection/drop evidence. Record any unavailable required check as pending, not as passed.

## Risks / Trade-offs

- Large images and pages still require significant active rendering memory → preserve per-file limits, bound worker/cache count, render preview viewports and measure the defined stress cases.
- System image/PDF calls may not stop mid-call → immediate cancellation feedback, safe boundary checks, and no partial publication.
- Source files can change while queued → identity/fingerprint validation and actionable per-item errors rather than silent content substitution.
- Output names can race with other writers → exclusive publication and suffix retry, never replacement.
- A crash can leave private staging → preserve the existing documented crash limitation; normal error/cancel cleanup is required. Persistent recovery management is outside this change.
- Existing historical specs still describe the original migration → retain its archive history, apply this change's deltas in chronological order, and do not re-sync the old migration over the new batch requirements later.

## Migration Plan

First extend and test page-addressable rendering and safe publication, then introduce batch state/lifecycle, then the native list/preview controls and progress flow. Replace obsolete single-file UI assertions while keeping core regression tests. Update README/security notes for batch naming, cancellation and queued-source behavior, and remove temporary verification helpers after retaining useful evidence. No user data migration or external credentials are needed.

Build the universal app and run native acceptance before declaring completion. Rollback is a source/app version rollback; original files are unchanged and already exported copies remain ordinary documents. Complete spec synchronization/archival in chronological order when finalizing the changes; GitHub distribution is a later independent proposal.
