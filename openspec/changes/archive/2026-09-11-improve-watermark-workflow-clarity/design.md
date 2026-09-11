## Context

See proposal.md for the problem and agreed scope. This design spans the SwiftUI workflow and shared watermark renderer because an editor-only multiline change would not guarantee matching exports.

The current ContentView uses fixed 240-point settings and 190-point file columns, with an 860 by 600 minimum window. Its single-line text binding retains the first 200 characters. Renderer.watermark normalizes geometry to an A4 shorter side and draws one CTLine per repeated mark. Existing batch metadata already supplies validation and page counts; export owns collision resolution and transactional writes. The installed app inspected through Finder reported version 2.0.1 while the checkout README reports 2.0.2, so acceptance must exercise a newly built bundle from this checkout.

## Goals / Non-Goals

**Goals:** Keep one shared settings model and one watermark layout path; derive export explanations from validated metadata; keep the fictional sample outside real file processing; verify visible behavior with synthetic documents.

**Non-Goals:** A new export engine, adaptive watermark density, automatic line wrapping, automatic font fitting, user profiles, saved templates, settings persistence across restart, sample export, new validation limits, warnings for invisible watermarks, or release/installation changes.

## Decisions

### 1. Keep the sample outside the batch

Generate a small fictional generic document locally using simple text and shapes, with no external image or realistic identity data. Render its watermark through the shared core path and label it Sample preview. Use current shared text and appearance settings; the sample is an appearance demonstration, not a promise about an unselected output format. Hide the file column only when the collection is empty. Any imported candidate, including a checking or invalid one, owns the real preview state until removed.

This avoids source identities, destination paths, cleanup rules, and export eligibility for demonstration content. A fake BatchItem was rejected because it could leak into export totals or error handling. A static illustration was rejected because adjustments would have no visible effect.

### 2. Put today’s date directly beside text editing

Remove the Help write my watermark button, its shortcut, and its recipient/purpose/date sheet. Place a native Include today’s date checkbox below the character count instead. It starts unchecked; initial text remains COPY. Checking it adds only `DD-MM-YYYY`, with no `Date:` label or other prefix, as a separate final line in the shared multiline editor, immediately updating sample/real previews and subsequent exports. Use the local date at the time of selection, a Gregorian calendar, and fixed `dd-MM-yyyy` formatting independent of locale: September 9, 2026 is `09-09-2026`, never `9-9-2026`. For example, September 11, 2026 is `11-09-2026`. The inserted date is literal text and does not roll over at midnight.

Unchecking removes the matching inserted date line and its separating newline, preserving other text. Checking must not duplicate an already-present exact today-date line; checkbox state follows the presence of that exact line after manual edits. The whole watermark remains directly editable. If the user edits or deletes that line, it becomes ordinary text and the checkbox becomes unchecked. No recipient or purpose fields, date picker, generation preview, or confirmation dialog remain.

Keep newline normalization and the 200-Swift-Character limit, including line breaks. On insertion, reserve room for the complete date line and its separator, retaining the leading existing text that fits; never insert a partial date. The editor and count show the resulting accepted text. Removing the date does not restore text previously truncated by the limit. This follows the agreed direct-editing behavior without adding mistake-preservation mechanisms. Keep the checkbox under the same export-time settings lock as the editor.

### 3. Share multiline geometry across output routes

Extend the normalized watermark layout to form one left-aligned block of explicit lines. Use the existing font and a fixed baseline distance of 1.2 times configured text size. Preserve blank lines; do not wrap, shrink, or increase user-selected pattern spacing to prevent overlap. Derive drawing bounds from the complete block so outer repeated blocks cover the visible page. Keep the first-line anchor and the existing single-line path/geometry unchanged. Preserve the existing diagonal angle, spacing grid, colors, and mode-specific opacity.

Preview and export must consume this same layout, including vector text in standard PDF and rasterized output. A UI-only layout or joining lines with spaces was rejected because it would break preview/output agreement. Automatic fit was rejected because it would silently change chosen settings. Tests compare single-line regression output and multiline parity across routes, including region-based previews. Multiline rendering visits only grid positions whose individual nonempty lines intersect the current clip; this bounds work for text with many blank lines without altering the chosen spacing or line breaks.

### 4. Make the panel flexible without rebuilding navigation

Use a native resizable divider with a starting settings width of 280 points and a minimum of 260. Bound expansion so the current file column, when visible, and at least 320 points of preview remain available; clamp the width when the window shrinks. The native split view starts at its 260-point minimum under the preview layout priority; 280 remains its ideal width. Both are wider than the previous 240-point panel, and direct divider resizing and the minimum-window layout were verified. Stack export labels above wide controls rather than truncating them. Use native callout-sized supporting text and adaptive system colors; preserve visible keyboard focus and accessible names. The existing scroll container handles expanded controls at minimum height. Do not persist widths or disclosure state across app restart in this change.

A fixed wider panel was rejected because users need to allocate space between settings and preview. Adding another navigation mode or moving export into a separate screen would expand the workflow unnecessarily.

### 5. Commit numeric drafts into valid shared settings

Provide a text draft beside each slider. Return or focus loss parses the local numeric format, commits finite values clamped to the existing range, or restores the last valid value for empty/nonnumeric/nonfinite input. Sliders update committed values and displayed drafts. Following the operator’s screenshot, make only the unfilled portion of the opacity, text-size, and spacing slider tracks black instead of grey, matching the dark background. Retain the blue filled portion and light thumb. Implement this with a native NSSlider bridge and a slider-cell bar-drawing override; keep native thumb rendering and tracking. Clicking a slider gives it keyboard focus so arrow keys adjust its value. Preserve visible keyboard focus, accessible slider semantics, and existing ranges and interactions. Keep fractional values valid so existing slider behavior is not changed; do not let incomplete text temporarily enter the renderer. Explain: Size and spacing scale with your document. Use percent only for opacity.

Reset appearance copies the five appearance defaults into shared settings in one update, leaving text, date selection, files, and output settings untouched. Preserve the existing export-time settings lock. Replacing controls with Small/Medium/Large was rejected because the operator chose precise values and existing ranges.

### 6. Derive predictions from the same eligibility and format rules as export

Create a pure summary representation based on current validation metadata and output policy; reuse existing eligibility and effective-format resolution rather than a separate guessed matrix. Count each ready image as one file and each ready PDF as one PDF or its page count in images. Count one output folder per PDF converted to images. Group counts by format and distinguish page-image folders from standalone image outputs. For example, a three-page PDF and a PNG exported as JPG produce 4 JPG images: 3 in one PDF folder and 1 standalone copy.

The button counts eligible source documents with singular/plural handling. No eligible documents use a disabled Export documents… label and an appropriate import/error hint. During checking, show Checking files… with any known counts explicitly partial; do not imply that the final total is known. Once checking finishes, summarize excluded invalid documents as well as eligible ones. Derive the summary again after collection or policy changes, not preview selection. Do not render files or inspect destinations just to predict output. Destination conflicts remain resolved by the exporter; explanatory text can describe naming rules without promising final names. During a run, retain current frozen settings and existing progress, cancel, and actual-result feedback.

### 7. Keep trust copy factual and respect operator intent

Show Processed on your Mac. Originals stay unchanged. near empty-state import and export. Preserve existing explanations of selectable versus flattened PDF behavior. Do not claim tamper-proof documents or general sanitization. Blank text and 0% opacity are legitimate choices: there is no warning, modal, fallback text, or export restriction for them. Numeric range enforcement and existing invalid-file checks remain necessary existing contracts, not new mistake-prevention features.

## Risks / Trade-offs

- Multiline rendering can alter single-line placement or miss lines in vector PDF output → keep single-line regression coverage and inspect reopened outputs, including extracted standard PDF watermark text.
- Long lines or dense multiline blocks can overlap → preserve explicit user settings and make the effect visible; automatic repair is outside scope.
- A sample could be mistaken for an imported document → use fictional content, an explicit label, no file-list entry, and no export eligibility.
- Wider settings reduce preview space → enforce divider bounds and visually check the 860 by 600 layout with real batch rows and expanded controls.
- Output predictions could diverge from actual eligibility → share pure policy/eligibility logic and test mixed formats, validation completion, and invalid exclusions.
- Quiet truncation is retained from existing text entry → expose the limit/count and show the exact accepted text after date insertion; do not add extra confirmation dialogs.

## Migration Plan

No persistent data migration or network/operator prerequisite is required. Implement shared text behavior first, then sample/date checkbox and control layout, then summary integration. Run focused tests and build the app; perform acceptance against that built bundle using fictional fixtures. Leave the installed app and release artifacts alone. Rollback consists of reverting the implementation change and rebuilding; no user files or settings require conversion.

## Acceptance Evidence

Record results in docs/workflow-clarity/acceptance.md during implementation, with synthetic screenshots and outputs in temporary or ignored paths unless the project explicitly tracks a sanitized fixture. Record the tested source revision, built bundle/version, commands, fixtures, observed failures, and unresolved checks without claiming unrun checks passed.

- Native first-use walkthrough: sample adjustments, cancel Add files, add/drop JPG/PNG/multipage PDF, select files, remove/clear back to the sample, and preserve shared settings.
- Date-checkbox walkthrough: initial unchecked state, insertion/removal, repeated toggles, an existing exact date line, manual edits, zero-padded month/day, local-date boundaries, and a >200-character composition that retains the complete date within the limit. Verify keyboard operation, preview/export agreement, and removal of the helper sheet/shortcut.
- Appearance walkthrough: numeric commits, invalid numeric drafts, slider synchronization, reset scope, blank text, and zero opacity without warnings.
- Layout evidence: light and dark appearances at 860 by 600 and a larger window, divider limits, collapsed/expanded Appearance, long text and filenames, complete keyboard workflow, and accessibility names for new controls. Change system appearance only through an authorized test method; do not silently alter the operator's system preferences.
- Core/output evidence: fictional JPG, PNG, and multipage PDF through every supported route, both PDF modes and representative DPI settings, multiline preview/export agreement, and unchanged single-line output.
- Batch evidence: mixed output totals, an invalid candidate, checking-to-ready transitions, cancelled destination selection, cancelled run, and existing actual saved/failed/unprocessed feedback. Reopen outputs and verify counts, page order, originals, and existing naming rules.
- Run focused affected suites first, then the repository's standard tests/build and relevant smoke checks required by the apply workflow. Existing compatibility and deterministic checks are not waived on the basis of screenshots.
