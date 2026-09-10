# native-watermark-workflow Specification

## Purpose

Provide a simple native Mac workflow for opening one document, previewing a configurable watermark, and exporting a copy with all existing adjustments available.

## Requirements

### Requirement: Batch native workflow
The app SHALL present one native macOS window with Add files, a selectable batch file list, shared watermark controls, one large selected preview and batch export. Less-used appearance adjustments SHALL remain collapsed by default. The full Appearance header SHALL be clickable to expand or collapse those adjustments. Native file and destination dialogs SHALL remain in use. The selected row SHALL show its filename and state; same-name inputs SHALL be distinguishable by location. Individual items SHALL be removable and the idle list SHALL be clearable. One-file use SHALL follow the same batch workflow without a separate legacy screen.

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

### Requirement: Preserve watermark settings
The app SHALL offer shared text up to 200 characters, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL be COPY, 30%, 36, 150, black, and ascending. Settings SHALL apply to every batch item and persist during additions, removals and selection changes. Initial output policy SHALL keep each input's format; explicit batch conversion choices SHALL persist independently of preview selection. Restart SHALL restore initial values and an empty batch. Watermark size and spacing SHALL scale with the shorter displayed side of each image or PDF page, using an A4 shorter side (210 mm at 72 points per inch) as the reference. The same settings SHALL produce equal relative text size and spacing regardless of source resolution or type; zoom SHALL NOT modify them. Saved presets and per-file overrides are outside this change.

#### Scenario: Adjust appearance
- **WHEN** the user expands adjustments and changes any supported setting
- **THEN** the selected preview and subsequent exports of every item reflect that setting without an additional Apply action

#### Scenario: Invisible or empty watermark
- **WHEN** the user supplies empty text or zero opacity
- **THEN** every preview and export contains no visible watermark and otherwise follows its effective output mode

#### Scenario: Selection preserves the shared configuration
- **WHEN** the user switches between a PDF, JPG and PNG after editing settings and choosing an output policy
- **THEN** watermark settings and output policy remain unchanged

### Requirement: Flattened PDF default and clear mode choice
The initial PDF mode SHALL be flattened at 450 DPI, with 300 and 600 DPI also available. Standard PDF mode SHALL remain available and preserve selectable source text. The choice SHALL be visible when exporting PDF input as a PDF, and quality SHALL be shown when flattening applies. The interface SHALL explain that standard watermarks can be edited separately and flattened pages lose ordinary text selection. It MUST NOT claim flattening prevents all removal, editing, or OCR.

#### Scenario: First PDF export
- **WHEN** the user opens a PDF in a fresh session and exports without changing its mode
- **THEN** the app exports a flattened PDF at 450 DPI

#### Scenario: Choose standard output
- **WHEN** the user selects standard mode
- **THEN** the app explains watermark removability and retains ordinary selectable source text in exported PDFs

### Requirement: Responsive and accurate preview
The preview SHALL update after input settles without blocking interaction and SHALL identify its file and, for PDFs, current page and total page count. PDF pages SHALL form one continuous vertical document, scrollable with two-finger trackpad gestures and a mouse wheel without snapping between pages. Previous/next controls SHALL smoothly navigate to adjacent pages, disabling navigation at the first and last pages. The current page SHALL follow the page containing the viewport center, or the nearest page when the center falls in a gap. Zoom-in, zoom-out and Fit to window SHALL be offered; zoomed content SHALL be scrollable in both axes. Trackpad pinch and Command + mouse wheel SHALL change zoom continuously around the pointer location; zoom buttons SHALL animate around the viewport center. Zoom SHALL retain the focused document position except where document-edge constraints require clamping, without clearing the displayed preview during interaction. Ordinary scrolling SHALL NOT change zoom. Fit to window SHALL fit the current page, with other PDF pages still available by scrolling. Scrolling SHALL preserve scale even when subsequent pages have different dimensions; explicit page navigation in fit mode SHALL fit its target page. Selecting a different file SHALL start at its first page and Fit to window. Page navigation SHALL preserve the chosen fit or manual zoom mode. Preview content SHALL match the selected file, page, shared settings and effective export policy, including watermark size, direction, opacity, page geometry and the existing PDF-to-image 72-DPI output. Reduced resolution is allowed, but zoom MUST NOT present magnified obsolete or low-resolution imagery as a completed detailed preview when more output detail is available. Outdated background results MUST NOT replace newer state.

#### Scenario: Rapid changes and document replacement
- **WHEN** the user rapidly changes settings, selected files or PDF pages while preview work is pending
- **THEN** the final visible preview belongs to the latest selection and shared settings
- **AND** export uses the current run snapshot rather than stale preview bytes

#### Scenario: Inspect a later rotated PDF page
- **WHEN** the user navigates to a later PDF page with different dimensions, crop or rotation
- **THEN** preview shows that page with correct geometry and watermark placement matching its exported appearance

#### Scenario: Inspect details and return to fit
- **WHEN** the user zooms into an image or PDF page, pans, then chooses Fit to window
- **THEN** the preview provides detail up to the actual output's resolution, followed by the whole page fitted into the available space
- **AND** exported dimensions and watermark settings are unchanged

#### Scenario: Scroll across page boundaries
- **WHEN** the user scrolls through a multipage PDF using a trackpad or mouse
- **THEN** adjacent pages move continuously through the viewport with correct geometry and a changing current-page indicator
- **AND** scrolling does not snap, reset the viewport, or change zoom

#### Scenario: Zoom from a fitted high-resolution photo
- **WHEN** a photo fits below 25% and the user pinches, uses Command + mouse wheel, or presses a zoom button
- **THEN** zoom starts from the displayed scale without jumping to 25%, preserves the focus position, and keeps document content visible while detail refines
- **AND** returning to fit displays the whole image

#### Scenario: Navigation during pending rendering
- **WHEN** the user scrolls or zooms while detailed rendering is pending on a large PDF
- **THEN** navigation stays interactive with correctly positioned available content and a visible loading indication where detail is pending
- **AND** delayed work cannot replace the current file, page geometry, settings, or output policy with obsolete content

#### Scenario: Fit a later page
- **WHEN** the user scrolls to a later page and chooses Fit to window
- **THEN** that entire page fits in the viewport and the rest of the PDF remains continuously scrollable
- **AND** selecting another file resets to its first page fitted to the window

### Requirement: Recoverable failures and export feedback
The app SHALL explain unsupported, corrupt, protected, oversized, unreadable and unwritable items in plain language beside the affected row. Adding or selecting an invalid item MUST NOT remove other valid items or display another item's preview as its own. Processing SHALL show busy state, prevent overlapping export runs and report success only after a complete input's outputs are committed. Runs SHALL continue past individual failures and end with accurate saved, failed and unprocessed counts. Cancellation and write failure SHALL leave the remaining collection and shared settings usable for another attempt.

#### Scenario: Recover after an invalid document
- **WHEN** adding a corrupt file fails and the user subsequently adds or selects a valid file
- **THEN** the app recovers without restart and no stale document or preview is exported

#### Scenario: Cancel or fail an export
- **WHEN** the destination dialog is cancelled, the run is cancelled or output writing fails
- **THEN** the app reports no false success, keeps sources usable and permits another export attempt

### Requirement: Readable selected filename
The selected filename SHALL appear in a full-width row above the preview controls, wrap to at most two lines, and expose the complete filename on hover and to accessibility tools. Names exceeding two lines SHALL truncate without overlapping controls. The row SHALL update with selection and clear when no file is selected.

#### Scenario: Long filename at minimum window size
- **WHEN** the user selects a file whose name exceeds the old toolbar space at the minimum supported window size
- **THEN** the header uses the available preview width and up to two lines without obscuring navigation
- **AND** the complete name is available on hover and through accessibility
