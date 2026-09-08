## 1. Normalize watermark geometry

- [x] 1.1 Add the A4 shorter-side normalization in the shared watermark renderer, scaling the whole pattern and preserving full-page phase for region rendering; verify every standard and raster export caller uses it exactly once.
- [x] 1.2 Add synthetic equivalent-document fixtures as PDF/JPG/PNG at multiple resolutions; test relative text size and spacing, the A4 baseline, both directions, boundary settings, empty text and zero opacity.
- [x] 1.3 Check reopened outputs and preview regions across image JPG/PNG/PDF, standard PDF, flattened 300/450/600 DPI, and PDF page-image routes, including rotated/cropped mixed-size pages. Assert unchanged output dimensions and existing opacity/PDF text semantics.

## 2. Continuous page layout and navigation state

- [x] 2.1 Add asynchronous page-size loading and a vertical page layout with centered pages and bounded gaps; test page rectangles, visible intersections and current-page selection for mixed dimensions and rotations.
- [x] 2.2 Separate current-page reporting, fit reference, manual zoom, scroll position and render completion in session state. Preserve scale during scrolling, fit explicit navigation targets, and reset only on file selection or explicit fit as designed.
- [x] 2.3 Extend the AppKit canvas to display the page stack and integrate previous/next navigation and current-page count. Verify first/last navigation boundaries and single-image behavior.

## 3. Responsive bounded preview rendering

- [x] 3.1 Schedule visible page regions first, provide provisional overview imagery and loading feedback, and allow immediate-neighbor prefetch within budget. Keep the existing output-detail ceiling and avoid full-document raster allocation.
- [x] 3.2 Account for retained decoded, overview and encoded preview content within 96 MiB and keep each render within 16 million pixels; evict offscreen detail and cancel superseded requests.
- [x] 3.3 Extend worker/session tests for rapid scrolling, zoom, setting changes, file replacement, cancellation, cache eviction and recoverable render failure. Ensure delayed results never appear on the wrong file or page and preview work cannot alter export snapshots.

## 4. Smooth scrolling and anchored zoom

- [x] 4.1 Wire native two-finger/mouse scrolling and trackpad momentum through the continuous canvas without snapping or viewport resets; keep ordinary scrolling independent of zoom.
- [x] 4.2 Implement pinch and Command + wheel zoom around the pointer, and animated 1.2-step buttons around the viewport center. Transform available imagery immediately and refine asynchronously.
- [x] 4.3 Implement anchor-preserving relayout, edge clamping, continuous transition from fit scales below 25%, fit/page animations, input interruption and Reduce Motion handling. Test fit scales outside manual limits, gap anchors, mixed pages, window resize and returning to fit.

## 5. Selected filename header

- [x] 5.1 Move the filename into a full-width row above preview controls with two-line wrapping, truncation, complete hover text and accessibility text; verify selection/removal updates at the minimum window size with long and non-Latin filenames.

## 6. Acceptance and regression evidence

- [x] 6.1 Run the Swift test suite and repository build checks; resolve regressions in format conversion, validation, local processing, metadata removal, source preservation, and standard/flattened PDF semantics.
- [x] 6.2 In the running macOS app, compare fitted previews and reopened exports using synthetic equivalents of the reported high-resolution photo and multipage PDF; record consistent relative watermark size and spacing without using personal documents as committed fixtures.
- [x] 6.3 Exercise real trackpad pinch and momentum, mouse wheel, Command + wheel, zoom/page buttons and Fit to window. Record smooth intermediate motion, retained focus, absence of blank/reset flashes, correct page count and detailed refinement after settling; explicitly mark any unavailable hardware check as pending.
- [x] 6.4 Stress a 50-page mixed-size PDF and a high-resolution image during rapid navigation and file/settings switches; record render/cache budget evidence and UI responsiveness. Confirm recovery after a preview failure and continued export correctness.
- [x] 6.5 Add acceptance notes covering fixtures, commands, observed results, screenshots or recordings, any pending evidence, and the intentional relative-sizing behavior change. Complete only after required acceptance checks pass.

Acceptance closed on 2026-09-08 by the user’s confirmation that everything works and explicit request to finalize, sync and archive. See `docs/preview/acceptance.md` for the sign-off and evidence provenance.
