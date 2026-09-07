## 1. Establish regression evidence and batch contracts

- [x] 1.1 Record the current native revision, run existing behavior tests, and capture release per-route export baselines using the existing synthetic fixtures; keep failures separate from behavior to preserve.
- [x] 1.2 Add deterministic native generation of the design's 100-file mixed corpus and 10-file subset, recording file identities, geometry and hashes; include 12-megapixel images and retain existing limit/rotation/annotation fixtures.
- [x] 1.3 Define ordered batch item, validation/export state, selection and shared output-policy contracts; verify original-format resolution, shared defaults and one-file behavior with focused tests.

## 2. Extend preview rendering without changing export semantics

- [x] 2.1 Make core preview requests page-addressable and resolve effective output settings per input; verify page bounds, first/middle/last page geometry and genuine JPG/PNG/PDF output policy behavior.
- [x] 2.2 Add scale/viewport-aware preview rendering with bounded buffers and a stable document coordinate origin; compare fit/zoom/panned results with saved output for standard, flattened and 72-DPI page-image routes.
- [x] 2.3 Implement preview request identity, revision checks, cancellation and the bounded cache; test rapid file/page/settings/zoom changes so stale results cannot replace current selection.

## 3. Build the collection and document lifecycle

- [x] 3.1 Add progressive background validation with metadata/fingerprint retention and bounded active document ownership; test exact existing limits and release of inactive decoded sources.
- [x] 3.2 Implement append, duplicate identity handling, individual removal, Clear all and deterministic selection changes; test repeated drops, symlinks/hardlinks, same-name distinct files and removal while validation is pending.
- [x] 3.3 Detect changed, removed and newly unreadable queued sources before reuse; provide actionable row errors and test that re-addition recovers without substituting stale or unreviewed content.
- [x] 3.4 Separate interactive preview scheduling from sequential background processing and own cancellation handles; verify selection stays usable during import/export and removed items cannot publish late results.

## 4. Implement safe per-input publication and batch runs

- [x] 4.1 Add deterministic `<stem>_watermarked` destination allocation, numeric suffixes and per-PDF image folders; test existing files/directories, same-name inputs, case/Unicode collisions and names matching any batch source.
- [x] 4.2 Stage and publish each input without replacement, including whole-folder publication for PDF image series; test a collision introduced after preflight and ensure existing files and all sources remain untouched.
- [x] 4.3 Add ordered batch execution with immutable settings/policy snapshots and independent per-file results; verify one failure does not stop later inputs, invalid rows are excluded visibly, and reruns create new copies.
- [x] 4.4 Propagate cancellation through processing boundaries and publication; deterministically test cancellation before work, during a PDF, before publication and immediately after publication, retaining only completed inputs.
- [x] 4.5 Expose file-based progress and accurate saved/failed/unprocessed summaries; test all-invalid, all-success, mixed-failure and cancelled runs plus subsequent recovery.

## 5. Build the native batch interface

- [x] 5.1 Replace single-file Open with multi-selection Add files and file drag-and-drop; preserve native panel cancellation, show append/duplicate/unsupported-input feedback, and wire remove/Clear all actions.
- [x] 5.2 Add the file list beside the large preview, shared-settings labeling, row status/errors and same-name location distinction; preserve collapsed appearance controls, keyboard access and usable layout at the minimum window size.
- [x] 5.3 Add previous/next PDF page controls, page counts, scrollable zoom and Fit to window; verify navigation boundaries, file-selection resets, page-change view behavior and image-specific controls.
- [x] 5.4 Add Keep original format/PDF/JPG/PNG policy and global PDF mode/quality controls, then wire Export all to one destination-folder dialog; verify preview selection never resets policy or shared settings.
- [x] 5.5 Wire busy/progress/Cancel/summary states and mutation guards; retain preview browsing during export and prevent false success, overlapping runs or stale images beneath another file's name.

## 6. Verify, document and clean up

- [x] 6.1 Run the complete mixed-file export matrix and retained native regressions for settings, encodings, metadata, geometry, standard text/vector/annotations/links, flattening DPIs, limits and source preservation.
- [x] 6.2 Extend the real native window smoke workflow for batch import, drag-and-drop, selection/removal, navigation/zoom, shared settings, folder cancellation, failure and export cancellation; record manual versus programmatic evidence accurately.
- [x] 6.3 Review representative saved outputs against first/middle/last-page fit and zoom previews, including mixed page geometry and transparent images; record visual findings and independently reopen PDF outputs.
- [x] 6.4 Measure the design's 100-file workload and 10-file subset in release mode; record raw UI acknowledgement/preview timings, import/export time, peak memory, per-route comparisons and the 50-page/600-DPI stress/cancellation case; resolve unmet acceptance budgets.
- [x] 6.5 Build the universal app and run native behavior and window/export checks on macOS 14 Apple Silicon and Intel CI; preserve runtime coverage and a clean native checkout verification.
- [x] 6.6 Update README/security notes and the requirement-to-evidence record; remove obsolete single-document UI paths/tests and temporary measurement helpers while retaining fixtures, useful native tests and results. Keep GitHub distribution out of this change and document chronological spec finalization.
