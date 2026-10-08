## Context

See proposal.md for motivation and review.md for current evidence. The renderer normalizes to the shorter displayed document side. `Renderer.watermark` (Renderer.swift:55–134) measures line widths and a multiline height, but uses `settings.spacing` unchanged for both lattice axes. The extent calculation affects coverage/culling, not collision prevention. Baselines are currently fixed at size × 1.2.

The shared renderer feeds sample rendering, image rendering, PDF rendering, regional previews, and standard PDF output. A preview-only correction would therefore create export discrepancies. Standard and raster routes deliberately have different opacity behavior, which this change preserves.

`BatchRunResult` (BatchExport.swift:46–56) has saved/failed/unprocessed counts, and `BatchExport.run` (93–138) starts failed at the number of invalid inputs. Session.startExport (Session.swift:402–431) captures the complete batch, while progress already counts only ready inputs. ContentView.swift:176–190 shows PDF controls based only on PDF presence. The settings column is a single ScrollView (ContentView.swift:16–23).

## Goals / Non-Goals

**Goals:**
- One measured layout shared by every rendering route, deterministic from full page geometry and settings.
- Bounded rendering for 200-character inputs, including many blank lines, and stable phase across regional preview tiles.
- Outcome categories based on the frozen run, independent of later validation-state updates.
- A compact action area that remains accessible while settings scroll.

**Non-Goals:**
- Automatic wrapping, font shrinking, content truncation, new opacity rules, or a separate preview pattern.
- Higher-resolution PDF page-image conversion, arbitrary colors, presets, per-file overrides, or a broad visual redesign.
- Changing system window-manager settings to make tests pass.

## Decisions

### 1. Derive safe pitches from the actual rotated block

Introduce a small shared layout value in WatermarkCore, populated from the accepted text, font metrics, direction, and requested spacing. Measure glyph bounds including fallback glyphs, ascenders/descenders, and every baseline; retain explicit blank lines in the block's layout height. Choose baseline separation as at least the current 1.2 × text size and enough for the measured line extents to avoid interline contact.

Build a padded, axis-aligned bounding box of the rotated complete block in normalized page coordinates. Start with a clearance proportional to text size (initial implementation target: 0.25 × size). Set the horizontal and vertical lattice pitches to the maximum of the requested spacing and the corresponding padded dimension. Maintain row staggering using half of the effective horizontal pitch. Axis-aligned separation is conservative but straightforward to verify for both diagonals, long lines, and multiple lines.

Retain the legacy placement path for non-overlapping single-line patterns that already satisfy the clearance test. For layouts requiring adaptation, anchor a complete block centrally when its rotated bounds fit the page. If it does not fit, center the ink of a nonempty line, or one actual glyph if that ink span is itself oversized, so a large block or long blank-line/space sequence cannot phase the watermark entirely off the document; edge clipping remains allowed. Use the full normalized page to choose the anchor, never the current preview clip.

Cull repetitions and lines against the render region analytically, retaining the existing protection against millions of invisible draws. Empty and all-whitespace text should exit early when no glyphs are drawable. Test broad phase bounds and visible output independently; a fast but empty renderer is not acceptable.

**Alternatives considered:** Raising the default spacing alone still fails for longer text and low slider values. Shrinking text or wrapping changes the user's choices. A rotated grid in text coordinates could pack stamps more densely but changes more existing geometry and complicates compatibility. Per-glyph collision packing adds complexity without a clear user benefit for this utility.

### 2. Treat spacing as a requested minimum

Keep stored values, range, default, numeric field, and slider synchronized as today. The automatic minimum can exceed the slider maximum internally; it must not be written back into the setting. Add short helper text such as “Longer text gets extra room to avoid overlap.” This avoids a second control and keeps keyboard editing predictable.

**Alternative:** Redefining the slider as an edge-to-edge gap would change every legacy setting, including the short COPY default. The minimum-pitch interpretation changes only cases needing extra room.

### 3. Split exclusions from attempted failures

Add an `excluded` count to BatchRunResult with a default of zero. Capture validation exclusions once from the run snapshot, initialize failed at zero, and increment failed only for an attempted eligible export that throws a non-cancellation error. Keep cancellation's uncommitted current input in unprocessed. Preserve invalid row explanations, update summary wording, and retain the identity `saved + failed + excluded + unprocessed == snapshot.count`.

Do not recalculate exclusions after an attempted source becomes invalid: it remains a failed attempt in that run and can become an exclusion on the next. Audit all result construction, equality assertions, summary uses, smoke fixtures, and documentation during implementation.

**Alternative:** Relabeling the existing failed total would hide real write failures. Separate accounting makes both cases explainable.

### 4. Keep the primary action outside the scrolling settings

Use a vertical settings column with a scrollable editor/appearance/options region and a compact fixed action area. Keep the action, a short eligible-document count, and busy/cancel replacement in the fixed area. Keep detailed output predictions and long help in the scrollable region. Preserve width constraints, the large preview, keyboard order, and current export locking.

**Alternative:** Making the whole window taller is unavailable on small screens. Collapsing Appearance automatically after editing hides choices unexpectedly.

### 5. Gate output controls on eligible effective routes

Derive whether any eligible PDF input will actually export as PDF. Use this predicate for PDF processing; require flattened mode as well for quality. When PDF page images are produced, show the actual fixed 72-DPI explanation and hide the unrelated PDF mode/quality selectors. Preserve stored choices when hidden and preserve current mode-specific watermark opacity, even on existing page-image paths.

Choose hiding inaccurate controls for this change. Adding configurable high-resolution PDF-to-image export changes memory demand, preview resolution, file size, and the existing output contract; it needs separate scoping.

## Risks / Trade-offs

- Fewer repetitions for long text → explicitly communicate automatic separation; compare realistic two- and three-line watermarks, not just COPY.
- Very long or tall text may not fit as a complete block → preserve content and font size, allow documented edge clipping, and guarantee a nonempty anchor where possible. Do not promise full visibility for text larger than the page.
- Conservative rotated bounding boxes may look sparse → tune the small proportional clearance through visual acceptance while retaining the no-collision invariant.
- Font fallback can exceed nominal font bounds → use actual glyph extents, test accented Latin, combining marks, emoji, CJK, and blank lines.
- Regional previews can drift if anchoring depends on their clip → compute layout once from full-page geometry and compare overlapping crop regions against exports.
- Added result field changes internal/public model shape → use a default value and audit all callers and result expectations.
- A fixed action area can crowd small windows → constrain its content, move detailed prose into scrolling content, and verify real light/dark layouts at the actual supported minimum size.
- Local window sizing test was inconclusive → record actual content bounds and distinguish environmental size refusal from application defects; rerun required minimum-size acceptance in a controllable graphical environment before claiming completion.

## Migration Plan

No persisted settings or document migration is required. Implement with regression fixtures first, update the shared layout and accounting, then apply native UI changes. Update README wording and acceptance evidence after verification. Do not publish a binary as part of this planning change. A later release can revert the implementation as a whole if rendering regressions appear; do not retain a preview-only rollback that differs from exports.
