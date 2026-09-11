## MODIFIED Requirements

### Requirement: Batch native workflow
The app SHALL present one native macOS window with Add files, a selectable batch file list when items exist, shared watermark controls, one large selected preview and batch export. Less-used appearance adjustments SHALL remain collapsed by default. The full Appearance header SHALL be clickable to expand or collapse those adjustments. Native file and destination dialogs SHALL remain in use. The selected row SHALL show its filename and state; same-name inputs SHALL be distinguishable by location. Individual items SHALL be removable and the idle list SHALL be clearable. One-file use SHALL follow the same batch workflow without a separate legacy screen.

#### Scenario: Open a document
- **WHEN** the user adds a supported image or PDF to an empty batch
- **THEN** that item is selected and its image or first PDF page appears with a watermark preview
- **AND** PDF page count is visible and export covers every page

#### Scenario: Initial and cancelled selection
- **WHEN** the app has no valid loaded items or the user cancels the Add files dialog
- **THEN** an empty app keeps export disabled, and cancellation leaves the existing batch unchanged

#### Scenario: Browse and remove items
- **WHEN** the user selects another file and then removes it
- **THEN** its preview is replaced with the next remaining item's preview, or the preceding item when no next item exists
- **AND** removing the final item restores the empty state without resetting shared settings

#### Scenario: Empty batch presentation
- **WHEN** no batch items exist on launch or after removing the last item
- **THEN** the Files column is hidden and the interactive Sample preview with a prominent Add files action and outlined drop area appears
- **AND** export remains disabled and removing items does not reset shared settings

### Requirement: Preserve watermark settings
The app SHALL offer shared multiline text up to 200 characters including line breaks, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL be COPY, 30%, 36, 150, black, and ascending. Settings SHALL apply to every batch item and persist during additions, removals and selection changes. Initial output policy SHALL keep each input's format; explicit batch conversion choices SHALL persist independently of preview selection. Restart SHALL restore initial values and an empty batch. Watermark size and spacing SHALL scale with the shorter displayed side of each image or PDF page, using an A4 shorter side (210 mm at 72 points per inch) as the reference. The same settings SHALL produce equal relative text size and spacing regardless of source resolution or type; zoom SHALL NOT modify them. Saved presets and per-file overrides are outside this change.

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

## ADDED Requirements

### Requirement: Interactive sample and clear import action
The empty state SHALL show a fictional document clearly labeled Sample preview, a prominent Add files… button, supported JPG/JPEG, PNG and PDF formats, and an outlined drop area with visible drag feedback. The sample SHALL reflect shared watermark text and appearance changes using the same watermark appearance as real documents. The sample MUST NOT be a batch item or an exportable document. Adding a real candidate SHALL reveal the file list and replace the sample with that item's checking, error, or real-preview state. Cancelling the picker SHALL preserve the current state. Sample settings SHALL carry into real documents. The sample SHALL reappear only when the batch is empty, not when all candidates are invalid.

#### Scenario: Learn before import
- **WHEN** the user changes text, opacity, size, spacing, color or direction in the empty app
- **THEN** the labeled sample updates and export remains disabled
- **AND** adding a valid document preserves those settings and replaces the sample with its preview

#### Scenario: Invalid first import
- **WHEN** the first imported file is invalid
- **THEN** the file list shows its error and the preview area shows that candidate's state instead of presenting the sample as its content
- **AND** removing it returns to the sample with current settings

#### Scenario: Cancel import or clear files
- **WHEN** the user cancels Add files or removes all real documents
- **THEN** cancellation leaves the current view unchanged, while an emptied batch shows the sample and hides the file list

### Requirement: Optional today’s date checkbox
The app SHALL replace the Help write my watermark button and helper sheet with an Include today’s date checkbox below the editor’s character count. The checkbox SHALL initially be unchecked and initial watermark text SHALL remain COPY. Selecting it SHALL insert a separate editable `DD-MM-YYYY` line with no `Date:` label or other prefix using today’s local date, Gregorian calendar, and zero-padded two-digit month and day, independently of locale. The selected date SHALL remain literal text until edited or toggled, without automatic midnight replacement. The checkbox SHALL share the editor’s export-time lock and SHALL be accessible by keyboard. No helper sheet, helper shortcut, recipient/purpose fields, or date picker SHALL remain.

#### Scenario: Insert and remove today’s date
- **WHEN** the user selects the checkbox on September 11, 2026
- **THEN** the editor includes a complete `11-09-2026` final line and sample/real previews and subsequent exports use the same text
- **AND** deselecting removes that matching date line and its separating newline without removing other text

#### Scenario: Repeat toggles and edit directly
- **WHEN** the exact today-date line already exists or the user repeatedly toggles the checkbox
- **THEN** selection does not duplicate the line and checkbox state reflects its presence
- **AND** editing or deleting that line directly clears the checkbox when the exact line is no longer present, while any edited text remains ordinary watermark text

#### Scenario: Date insertion at the character limit
- **WHEN** adding the date would exceed 200 characters including line breaks
- **THEN** insertion reserves room for the complete date and separating newline, retains the leading existing text that fits, and updates the editor and accepted count to the resulting text
- **AND** no partial date, warning, or confirmation is introduced, and deselection does not restore truncated text

### Requirement: Readable resizable settings
The settings panel SHALL be wider by default than the current 240-point panel and resizable while preserving a usable document preview at the supported 860 by 600 point minimum window size. Labels and the selected export format SHALL be readable without clipping or truncation; controls SHALL wrap or stack when necessary. Supporting explanations SHALL use at least the native callout text style and readable contrast in light and dark appearances. Appearance SHALL remain collapsed initially. New controls SHALL expose accessible names and keyboard operation, with visible focus; the primary workflow SHALL be operable without a pointer. Expanded settings SHALL remain reachable by scrolling.

#### Scenario: Minimum window and keyboard use
- **WHEN** the app is at 860 by 600 points with a file list present and Appearance expanded
- **THEN** watermark editing, appearance, export options, and action labels remain readable and reachable in either appearance
- **AND** keyboard navigation can reach and operate import, date checkbox, editor, numeric controls, reset, and export

#### Scenario: Resize the settings panel
- **WHEN** the user drags the settings divider within its allowed bounds
- **THEN** the panel resizes without hiding controls or making the preview unusable

### Requirement: Precise appearance editing and scoped reset
Opacity, text size, and spacing SHALL each offer a synchronized slider and editable numeric value within their existing ranges. The unfilled portion of each appearance slider track SHALL be black to match the dark background rather than grey. The blue filled portion, light thumb, and visible keyboard focus SHALL remain. Opacity SHALL show percent; size and spacing SHALL explain that they scale with the document rather than presenting values as fixed pixels. Numeric editing SHALL commit on Return or focus loss, clamp finite out-of-range values to the existing range, and restore the prior valid value for empty or nonnumeric input. Reset appearance SHALL restore opacity 30%, size 36, spacing 150, black color, and ascending direction immediately, without changing text, date selection, files, or output settings. Shared controls SHALL retain the existing export-time lock.

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
Before export, the app SHALL show a live summary of eligible source document count and expected output file counts grouped by effective format. PDF-to-image conversion SHALL explain that each PDF produces a separate folder of page images; image inputs SHALL remain individual files. The action SHALL read Export 1 document… or Export N documents… and count eligible source documents, not pages or output files. While validation is pending, the summary SHALL identify checking as incomplete rather than claiming a final total, and export SHALL remain disabled under the existing rules. Invalid items SHALL be identified as excluded; an empty batch SHALL give an import hint without implying the sample can be exported. Counts SHALL update after additions, removals or format changes and SHALL NOT depend on preview selection. The summary SHALL describe expected outputs, not promise successful writes. Existing native folder selection, collision naming, actual saved/failed/unprocessed feedback, cancellation, and Reveal in Finder SHALL remain intact.

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

### Requirement: Accurate local-processing reassurance
The import area and export controls SHALL show Processed on your Mac. Originals stay unchanged. or equivalent wording. This reassurance MUST NOT claim that watermarking prevents editing or reuse, or that all PDFs are sanitized. The date checkbox and fictional sample SHALL work offline and SHALL NOT introduce uploads, accounts, telemetry, or logging of document or watermark contents.

#### Scenario: Offline first use and export
- **WHEN** the app is used without a network connection
- **THEN** the sample, date checkbox, import, preview, and export remain usable and the local-processing reassurance is visible at import and export
