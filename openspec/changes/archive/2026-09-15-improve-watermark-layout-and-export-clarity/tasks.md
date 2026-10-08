## 1. Watermark layout regressions

- [x] 1.1 Add regression fixtures for the observed rental-purpose, accented-name, and date watermark, long single lines, both diagonals, size 72, and spacing 50; assert separation between complete blocks and between their lines.
- [x] 1.2 Cover combining marks, fallback emoji/CJK glyphs, explicit blank lines, all-whitespace text, and accepted 200-character inputs; assert bounded work and visible content for oversized blocks.
- [x] 1.3 Qualify legacy geometry assertions to patterns that already have sufficient clearance, retaining a pixel comparison for the default COPY pattern and invisible-output tests.

## 2. Shared adaptive rendering

- [x] 2.1 Introduce shared layout measurements using actual glyph extents and baseline separation, preserving explicit line breaks and font size.
- [x] 2.2 Compute padded rotated block bounds and effective horizontal/vertical pitches from the requested minimum; preserve the legacy placement path when safe and stagger adaptive rows consistently.
- [x] 2.3 Anchor adaptive layouts from full page geometry, place a complete block when it fits, and retain a nonempty anchor with permitted edge clipping for oversized blocks; analytically cull invisible repetitions and lines.
- [x] 2.4 Audit all renderer callers and use the same layout in sample, image, PDF, and regional preview routes; verify normalized geometry, crop alignment, and unchanged output dimensions and mode-specific opacity.

## 3. Accurate export outcomes

- [x] 3.1 Add a default-zero excluded count to the run result, capture validation exclusions from the frozen snapshot, and reserve failed for attempted eligible exports that fail.
- [x] 3.2 Update result construction and summary consumers, retaining eligible-only progress and saved-output reveal; test successful mixed batches, isolated write failures, cancellation, and changed sources across consecutive runs.
- [x] 3.3 Assert that saved, failed, excluded, and unprocessed counts partition the full frozen source collection exactly once, including cancellation of an in-progress input.

## 4. Clear and reachable native controls

- [x] 4.1 Move the export action, concise eligible count, and running progress/Cancel into a compact fixed area outside scrolling settings; preserve validation rules, export locking, and keyboard access.
- [x] 4.2 Gate PDF processing on eligible PDF-to-PDF outputs and flattening quality on flattened output; hide both for page-image conversion and show its fixed 72-DPI sizing, retaining stored settings.
- [x] 4.3 Explain automatic watermark separation beside spacing without replacing the requested slider/numeric value; verify synchronization, clamping, reset, and date/text preservation.
- [x] 4.4 Verify control applicability for mixed, image-only, invalid-PDF, and empty batches, including switching output policies and standard/flattened modes.

## 5. Verification and documentation

- [x] 5.1 Run native tests and the universal app build, then the format matrix and bounded-rendering regressions; reopen representative exports to verify collision-free text and unchanged standard/flattened semantics.
- [x] 5.2 Visually compare realistic multiline preview and saved output across both directions, images, rotated/cropped PDF pages, standard PDF, flattened 300/450/600-DPI PDF, and PDF page images; include panned and zoomed regional previews.
- [x] 5.3 Verify the actual 860-by-600-point content size in a controllable graphical session, in light and dark appearances, with Appearance expanded and a mixed batch; inspect fixed actions, scrolling, focus, and labels. Record an environmental size refusal as unresolved rather than passed.
- [ ] 5.4 Exercise keyboard navigation, VoiceOver labels, Finder drag-and-drop, physical pinch/scroll gestures, cancellation, repeated export naming, and Reveal in Finder; record platform coverage and any remaining acceptance limits explicitly.
- [x] 5.5 Update README behavior descriptions and acceptance records with measured results, artifact locations, and honest benchmark conditions; refresh the graft graph after implementation and validate the completed OpenSpec change. Binary release remains a separate task.
