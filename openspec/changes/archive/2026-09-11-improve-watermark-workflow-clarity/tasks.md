## 1. Shared multiline watermark behavior

- [x] 1.1 Add shared newline normalization and 200-character handling for editor text; test line breaks, Unicode, boundary lengths, and empty text.
- [x] 1.2 Extend shared watermark rendering to explicit multiline blocks with the design's line spacing and preserved single-line geometry; cover both directions, blank lines, normalized sizing, and region-preview alignment.
- [x] 1.3 Verify multiline output through JPG/PNG/image-to-PDF, standard PDF, flattened PDF, and PDF page-image routes; check standard PDF text extraction, flattened text-layer behavior, and single-line regression output.

## 2. First-use sample and text editing

- [x] 2.1 Create a locally generated fictional Sample preview using the shared watermark renderer, outside batch eligibility; update it with current text and appearance without introducing network access or exportable sample files.
- [x] 2.2 Add prominent empty-state import and an outlined drop area with drag feedback; hide the file list only for an empty batch and verify checking/invalid first imports, picker cancellation, clear/remove, and settings retention.
- [x] 2.3 Replace the single-line field with an accessible multiline editor and accepted-character count; preserve COPY defaults, line breaks, current limit behavior, and export-time locking.
- [x] 2.4 Replace the implemented helper button, sheet, draft state, and shortcut with an accessible Include today’s date checkbox. Implement insertion/removal, exact-line deduplication and manual-edit synchronization, fixed zero-padded local DD-MM-YYYY formatting without a Date: prefix, complete-date insertion within 200 characters, and export-time locking.

## 3. Readable settings and precise appearance controls

- [x] 3.1 Make the settings panel wider and resizable with bounded preview space; stack or wrap controls to avoid truncated labels at 860 by 600 and keep expanded controls scrollable.
- [x] 3.2 Add numeric drafts synchronized with sliders, local numeric parsing, Return/focus-loss commit rules, and document-relative size/spacing explanation; test invalid drafts and range boundaries without changing rendering ranges.
- [x] 3.3 Implement Reset appearance for only opacity, size, spacing, color, and direction; verify text, collection, and export choices remain intact.
- [x] 3.4 Improve supporting text sizes and adaptive contrast, accessible control labels, and visible keyboard focus; keep Appearance initially collapsed and preserve existing keyboard shortcuts.

## 4. Export explanation and factual reassurance

- [x] 4.1 Derive a testable export summary from the exporter's eligibility/effective-format rules and validation metadata; cover every policy, multipage counts, per-PDF image folders, standalone image outputs, invalid exclusions, and checking transitions.
- [x] 4.2 Integrate the live summary and source-document-count action label with singular/plural and empty-state handling; verify updates follow collection/policy changes independently of preview selection and preserve destination selection, progress, cancellation, actual results, and Reveal in Finder.
- [x] 4.3 Add Processed on your Mac. Originals stay unchanged. near import/export while retaining accurate PDF mode explanations; verify no new warning, fallback, confirmation, or export restriction for blank text or 0% opacity.

## 5. Acceptance and documentation

The operator confirmed on 2026-09-11 that direct file dragging works, completing the original acceptance in task 5.2. The original date-checkbox revision was implemented and verified. Tasks 2.4 and 6.1–6.3 also verify the implemented prefix-free DD-MM-YYYY format; the previous helper checks describe the originally implemented UI.

- [x] 5.1 Run focused native/core tests covering the changed behavior, then the standard test suite and build plus relevant smoke checks; resolve deterministic failures and identify the newly built bundle used for visual checks.
- [x] 5.2 Use the built app with fictional JPG, PNG, and multipage PDF fixtures to exercise sample-to-import, helper-to-editor, settings-to-preview, mixed export, invalid input, destination cancellation, and run cancellation; reopen outputs to verify predicted counts, page order, matching watermark appearance, source preservation, and naming.
- [x] 5.3 Visually verify light/dark appearance at minimum and larger window sizes, panel resize bounds, expanded/collapsed controls, long filenames/text, and the full keyboard workflow; inspect accessibility names for new controls and verify the helper/sample remain usable offline.
- [x] 5.4 Update the user-facing workflow documentation and record actual acceptance evidence in docs/workflow-clarity/acceptance.md with synthetic fixtures, tested revision/bundle, commands, results, and remaining limitations. Keep generated outputs temporary or ignored and leave unperformed checks explicitly pending.
- [x] 5.5 Refresh the repository context graph after the code changes, validate the OpenSpec change, and review the final diff against all seven agreed improvements and the explicit no-warning decision before declaring implementation complete.

## 6. Date-checkbox revision acceptance

- [x] 6.1 Update focused tests for prefix-free DD-MM-YYYY ordering (11-09-2026), zero-padded month/day, local-date boundaries, insertion/removal, repeated toggles, existing date lines, manual edits, empty text, and complete-date insertion at the character limit. Confirm preview/export share the resulting text and blank/zero-opacity choices remain unrestricted.
- [x] 6.2 Rebuild and visually verify the prefix-free DD-MM-YYYY date in the editor, preview, and output. Verify the revised native UI at minimum size in light/dark appearance: helper button/sheet/shortcut absent, date checkbox visible and keyboard-operable, editor/count and preview synchronized, reset preserves date/text, and controls locked during export. Run the relevant standard tests and smoke checks.
- [x] 6.3 Update README and acceptance evidence for the checkbox, record the operator’s successful drag check and the revised tested bundle, refresh the repository context graph, and validate the final OpenSpec change.

## 7. Slider appearance refinement

- [x] 7.1 Make the unfilled portion of the opacity, text-size, and spacing slider tracks black instead of grey, matching the supplied screenshot’s intended correction. Retain blue filled portions and light thumbs, focus, accessibility, ranges, and synchronized numeric values.
- [x] 7.2 Verify the rebuilt sliders visually in light and dark appearances and exercise pointer and keyboard adjustment; record the results in acceptance evidence.
