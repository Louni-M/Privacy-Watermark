## Context

See proposal.md for motivation and the delta specs for agreed behavior. Renderer.watermark currently applies the same size/spacing directly to image pixels and PDF points. PreviewHost has a single-page canvas; Session.setZoom clears its image, increments the reset counter, and clamps to 25–400%. Preview work is debounced and only renders the current viewport. PreviewWorker retains one source and a 96 MiB cost-accounted cache; PreviewRendering limits each render to 16 million pixels. These constraints need to survive a multipage canvas.

## Goals / Non-Goals

**Goals:** Centralize watermark geometry across all rendering routes; separate immediate viewport motion from background detail generation; use bounded rendering for a continuous page layout.

**Non-Goals:** A second PDFKit-only viewer, eagerly rasterizing whole PDFs, changing opacity/compositing, or introducing a dependency. See proposal.md for product exclusions.

## Decisions

### Normalize watermark coordinates once

Use reference length `210 / 25.4 * 72` (A4 shorter side). For each displayed page/image, derive `factor = min(width, height) / reference`. Draw the entire watermark pattern in a normalized coordinate system: scale the watermark drawing context by factor and divide the document extent by factor. This scales font size, spacing, offsets and padding together while leaving user settings and validation unchanged. Use full displayed dimensions even for region rendering, so neighboring regions share pattern phase. Preserve PDF crop/rotation handling and all existing raster/vector opacity branches.

Centralize this in the shared watermark renderer, covering standard vector PDF calls as well as raster calls. Resizing source images would lose detail; DPI metadata is unreliable and would make identical pixel content behave differently. Scaling only font size would leave density inconsistent.

### One AppKit scroll document with page layout metadata

Extend the existing NSScrollView canvas to lay out every page vertically with a 16-point screen-space gap and horizontal centering. Obtain displayed page sizes off the main thread; keep rectangles and identity separate from raster content. Images use the same layout with one page. Render visible page intersections first; retain a bounded whole-page overview for visible pages and prefetch only immediate neighbors when idle and budget permits. Do not allocate an image for the full PDF strip.

The current page is the page under the viewport center, or the nearest page across a gap (ties select the earlier page). Update its indicator from layout, without triggering page-reset behavior. Page buttons target the adjacent current page, animate its top into view, and fit it if fit mode is active. Manual zoom remains the same across button navigation. Ordinary scrolling keeps scale fixed, including across mixed page sizes.

Keep a fit reference page stable during scrolling; Fit to window explicitly selects the current page as that reference. Window resizing in fit mode recalculates against the reference page and preserves the visible document anchor. Opening a different file selects page one and resets fit mode. This avoids scale feedback loops as the current-page indicator changes.

### Immediate anchored transforms and asynchronous refinement

Maintain view mode, effective scale and scroll origin independently from rendered image completion. Convert the pointer location (gesture/wheel) or viewport center (buttons) to a page-local anchor before changing scale, then restore that anchor on screen after relayout, clamping at document edges. Resolve anchors in gaps to the closest point on a page. Fit/page buttons animate to their target; user input interrupts ongoing animations. Honor macOS Reduce Motion by removing optional button animations while retaining direct gesture tracking.

Pinch uses continuous magnification; Command + wheel uses continuous multiplicative zoom; ordinary wheel events remain native scrolling with trackpad momentum. Buttons target a multiplicative 1.2 step with an approximately 180 ms interruptible animation. These timing defaults can be tuned during acceptance without changing behavior. Preserve the 400% manual maximum, but always admit a fit scale outside manual bounds; use a manual lower bound of min(1%, fit scale), and move continuously from any fitted scale into the allowed manual range. No first-input jump to 25%.

While interacting, transform available imagery immediately and request refinement asynchronously. Show overview content/loading state for newly exposed areas instead of clearing the canvas. A low-resolution image is provisional until sufficient available output detail arrives. Keep debouncing expensive detail work, but do not debounce the visual transform.

### Bound and version preview work

Extend preview identity to include file fingerprint, revision, page index, output policy and per-page region/scale. Associate results with their own page and geometry; viewport changes can reuse correctly positioned same-revision overview content, but never accept obsolete settings or file results. Prioritize the latest visible regions and cancel superseded queued work. A single worker can keep rendering serialized initially; no parallel rendering pool is needed.

Retain the 16-million-pixel render ceiling and 96 MiB retained-preview budget, accounting for decoded displayed/overview images as well as cached encoded bytes. Cap simultaneous scratch work and evict offscreen detail first. Allocation failures produce recoverable preview errors; never substitute another file's content. Source-validation and export snapshot behavior remain unchanged.

### Filename belongs above the preview

Move the selected filename out of the constrained toolbar into the preview's full-width header, above navigation. Allow two lines and truncation beyond that, with full-text hover help and accessibility text. Retain the existing sidebar width. Keep the header stable during rendering and derive it directly from the selected item.

## Risks / Trade-offs

- Relative sizing intentionally changes existing image/non-A4 output appearance → document the change and compare normalized geometry rather than requiring legacy pixel density.
- Continuous pages increase memory pressure → bounded visible/neighbor rendering, shared accounting and a 50-page stress fixture; never retain every page raster.
- Geometry feedback can cause jitter → separate current-page reporting, fit reference, viewport state and render completion; test anchor math and mixed-size layouts.
- Native input feel needs hardware validation → test trackpad pinch/momentum, mouse wheel and Command + wheel in the running app; retain evidence instead of relying only on automated tests.
- Existing mode-specific opacity can still look different → preserve it deliberately; this change standardizes geometry only.

## Migration Plan

Implement shared scaling and its regression checks first, then page layout/state, bounded rendering, interactions and header. Validate the full preview/export matrix and existing privacy/source-preservation tests. No saved-state or data migration is required because settings reset at launch and sources are untouched. Rollback means reverting the code changes; already exported copies remain as generated. Release publication is outside this planning workflow. No credentials, external service setup or operator-only prerequisite is needed.
