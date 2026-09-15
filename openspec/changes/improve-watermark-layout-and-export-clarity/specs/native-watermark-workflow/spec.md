## MODIFIED Requirements

### Requirement: Preserve watermark settings
The app SHALL offer shared multiline text up to 200 characters including line breaks, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL be COPY, 30%, 36, 150, black, and ascending. Settings SHALL apply to every batch item and persist during additions, removals and selection changes. Initial output policy SHALL keep each input's format; explicit batch conversion choices SHALL persist independently of preview selection. Restart SHALL restore initial values and an empty batch. Watermark size and spacing SHALL scale with the shorter displayed side of each image or PDF page, using an A4 shorter side (210 mm at 72 points per inch) as the reference. Spacing SHALL be a requested minimum repetition pitch, automatically increased when required to separate the complete watermark blocks. The same settings and text SHALL produce equal relative text size and effective separation regardless of source resolution or type; zoom SHALL NOT modify them. Saved presets and per-file overrides are outside this change.

The editor SHALL preserve explicit line breaks and expose the 200-character limit with a character count. Text entry and today-date insertion SHALL obey the same limit. Blank text and zero opacity SHALL NOT cause a warning, confirmation, or additional export restriction.

#### Scenario: Adjust appearance
- **WHEN** the user expands adjustments and changes any supported setting
- **THEN** the selected preview and subsequent exports of every item reflect that setting without an additional Apply action

#### Scenario: Invisible or empty watermark
- **WHEN** the user supplies empty text or zero opacity
- **THEN** every preview and export contains no visible watermark and otherwise follows its effective output mode

#### Scenario: Selection preserves the shared configuration
- **WHEN** the user switches between a PDF, JPG and PNG after editing settings and choosing an output policy
- **THEN** watermark settings and output policy remain unchanged

#### Scenario: Multiline editing and character limit
- **WHEN** the user enters or pastes multiple lines, including text beyond 200 characters
- **THEN** explicit line breaks within the accepted first 200 characters remain editable and previewed, and the character count reflects the accepted text
- **AND** typing Return inserts a line break rather than starting export

### Requirement: Flattened PDF default and clear mode choice
The initial PDF mode SHALL be flattened at 450 DPI, with 300 and 600 DPI also available. Standard PDF mode SHALL remain available and preserve selectable source text. The choice SHALL be visible only when at least one eligible PDF input has PDF as its effective output, and quality SHALL be shown only when flattening applies to such an output. Invalid PDFs and image-to-PDF conversions alone SHALL NOT activate these controls. PDF-to-JPG and PDF-to-PNG output SHALL retain fixed 72-DPI page sizing and show that resolution explicitly without displaying an unrelated 300/450/600-DPI quality selector. Switching output policy SHALL retain the stored PDF settings so switching back restores them. Hidden PDF processing settings SHALL retain their existing effect on route-specific watermark opacity; this change SHALL NOT silently change that rendering behavior. The interface SHALL explain that standard watermarks can be edited separately and flattened pages lose ordinary text selection. It MUST NOT claim flattening prevents all removal, editing, or OCR.

#### Scenario: First PDF export
- **WHEN** the user opens a PDF in a fresh session and exports without changing its mode
- **THEN** the app exports a flattened PDF at 450 DPI

#### Scenario: Choose standard output
- **WHEN** the user selects standard mode
- **THEN** the app explains watermark removability and retains ordinary selectable source text in exported PDFs

#### Scenario: PDF pages exported to images
- **WHEN** a batch containing an eligible PDF is changed to JPG or PNG output
- **THEN** the PDF mode and flattening quality selectors disappear and the output description states that PDF pages use 72 DPI
- **AND** returning to PDF output restores the previously chosen PDF mode and quality

#### Scenario: No eligible PDF-to-PDF output
- **WHEN** only image inputs or invalid PDFs exist, including image-to-PDF conversion
- **THEN** PDF processing and flattening quality selectors are hidden


### Requirement: Recoverable failures and export feedback
The app SHALL explain unsupported, corrupt, protected, oversized, unreadable and unwritable items in plain language beside the affected row. Adding or selecting an invalid item MUST NOT remove other valid items or display another item's preview as its own. Processing SHALL show busy state, prevent overlapping export runs and report success only after a complete input's outputs are committed. Runs SHALL continue past individual failures and end with accurate saved, failed, excluded and unprocessed counts. Excluded SHALL identify inputs invalid before the run; failed SHALL identify eligible inputs whose attempted export failed; unprocessed SHALL identify eligible inputs without a completed attempt, including work interrupted by cancellation. Cancellation and write failure SHALL leave the remaining collection and shared settings usable for another attempt.

#### Scenario: Recover after an invalid document
- **WHEN** adding a corrupt file fails and the user subsequently adds or selects a valid file
- **THEN** the app recovers without restart and no stale document or preview is exported

#### Scenario: Cancel or fail an export
- **WHEN** the destination dialog is cancelled, the run is cancelled or output writing fails
- **THEN** the app reports no false success, keeps sources usable and permits another export attempt

### Requirement: Readable resizable settings
The settings panel SHALL be wider by default than the current 240-point panel and resizable while preserving a usable document preview at the supported 860 by 600 point minimum window size. Labels and the selected export format SHALL be readable without clipping or truncation; controls SHALL wrap or stack when necessary. Supporting explanations SHALL use at least the native callout text style and readable contrast in light and dark appearances. Appearance SHALL remain collapsed initially. New controls SHALL expose accessible names and keyboard operation, with visible focus; the primary workflow SHALL be operable without a pointer. Expanded settings and detailed explanations SHALL remain reachable by scrolling. The primary export action, or its progress and cancellation replacement during a run, and a concise eligible-document count SHALL remain visible outside the scrolling settings area at every supported window size. This fixed area SHALL remain compact enough to leave the editor and appearance controls usable. The idle action SHALL retain its disabled state when no eligible document exists.

#### Scenario: Minimum window and keyboard use
- **WHEN** the app is at 860 by 600 points with a file list present and Appearance expanded
- **THEN** watermark editing, appearance, export options, and action labels remain readable and reachable in either appearance
- **AND** keyboard navigation can reach and operate import, date checkbox, editor, numeric controls, reset, and export

#### Scenario: Resize the settings panel
- **WHEN** the user drags the settings divider within its allowed bounds
- **THEN** the panel resizes without hiding controls or making the preview unusable

#### Scenario: Export after changing appearance
- **WHEN** Appearance is expanded with a mixed batch at 860 by 600 points and the user scrolls the settings panel
- **THEN** the export action and concise eligible count remain visible and operable without scrolling back
- **AND** all detailed controls remain reachable without overlapping the fixed action area

#### Scenario: Running and cancelled export
- **WHEN** an export is running with settings scrolled away from the bottom
- **THEN** progress and Cancel remain visible in the action area
- **AND** completion or cancellation restores the export action with the existing eligibility rules


### Requirement: Precise appearance editing and scoped reset
Opacity, text size, and spacing SHALL each offer a synchronized slider and editable numeric value within their existing ranges. The unfilled portion of each appearance slider track SHALL be black to match the dark background rather than grey. The blue filled portion, light thumb, and visible keyboard focus SHALL remain. Opacity SHALL show percent; size and spacing SHALL explain that they scale with the document rather than presenting values as fixed pixels. The spacing explanation SHALL also state that longer text automatically gets additional room to prevent overlap. The numeric value and slider SHALL show the requested minimum, not rewrite the user’s setting to an out-of-range effective pitch. Numeric editing SHALL commit on Return or focus loss, clamp finite out-of-range values to the existing range, and restore the prior valid value for empty or nonnumeric input. Reset appearance SHALL restore opacity 30%, size 36, spacing 150, black color, and ascending direction immediately, without changing text, date selection, files, or output settings. Shared controls SHALL retain the existing export-time lock.

#### Scenario: Black slider interiors
- **WHEN** the user views or adjusts opacity, text size, or spacing
- **THEN** each slider track has a black unfilled portion instead of grey, with its blue filled portion and light thumb retained
- **AND** the thumb, focus indication, pointer operation, and keyboard adjustment remain usable

#### Scenario: Numeric edits
- **WHEN** the user types a valid size, changes spacing with its slider, or commits an invalid numeric value
- **THEN** valid edits synchronize the slider, number, preview and subsequent export; invalid values follow the commit rules without entering rendering state

#### Scenario: Reset appearance
- **WHEN** the user resets appearance after changing text, appearance and output format
- **THEN** only the five appearance values return to defaults and the current preview updates

### Requirement: Predictable export summary
Before export, the app SHALL show a live summary of eligible source document count and expected output file counts grouped by effective format. PDF-to-image conversion SHALL explain that each PDF produces a separate folder of page images; image inputs SHALL remain individual files. The action SHALL read Export 1 document… or Export N documents… and count eligible source documents, not pages or output files. While validation is pending, the summary SHALL identify checking as incomplete rather than claiming a final total, and export SHALL remain disabled under the existing rules. Invalid items SHALL be identified as excluded; an empty batch SHALL give an import hint without implying the sample can be exported. Counts SHALL update after additions, removals or format changes and SHALL NOT depend on preview selection. The summary SHALL describe expected outputs, not promise successful writes. Existing native folder selection, collision naming, actual saved/failed/excluded/unprocessed feedback, cancellation, and Reveal in Finder SHALL remain intact.

#### Scenario: Mixed PDF page-image export
- **WHEN** a validated three-page PDF and one PNG are selected for JPG export
- **THEN** the summary identifies 2 source documents and 4 JPG images, with the PDF's 3 page images in its own folder and the PNG's copy outside that folder
- **AND** the action reads Export 2 documents…

#### Scenario: Keep original format
- **WHEN** a validated three-page PDF and one PNG retain their original formats
- **THEN** the summary identifies 2 documents producing 1 PDF and 1 PNG, and does not count the PDF pages as separate output files

#### Scenario: Pending or invalid inputs
- **WHEN** a batch includes checking or invalid candidates
- **THEN** pending counts are visibly incomplete, invalid items are excluded from eligible counts, and export is enabled only after checking finishes with at least one eligible document

#### Scenario: Successful export with excluded files
- **WHEN** a batch has three eligible and three invalid source documents and every eligible export succeeds
- **THEN** the result reports three saved, zero failed, three excluded, and zero not processed
- **AND** invalid rows retain their original validation explanations and Reveal in Finder targets only saved outputs
