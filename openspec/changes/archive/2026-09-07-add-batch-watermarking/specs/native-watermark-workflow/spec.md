## RENAMED Requirements

- FROM: `### Requirement: Single-document native workflow`
- TO: `### Requirement: Batch native workflow`

## MODIFIED Requirements

### Requirement: Batch native workflow
The app SHALL present one native macOS window with Add files, a selectable batch file list, shared watermark controls, one large selected preview and batch export. Less-used appearance adjustments SHALL remain collapsed by default. Native file and destination dialogs SHALL remain in use. The selected row SHALL show its filename and state; same-name inputs SHALL be distinguishable by location. Individual items SHALL be removable and the idle list SHALL be clearable. One-file use SHALL follow the same batch workflow without a separate legacy screen.

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
The app SHALL offer shared text up to 200 characters, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL remain COPY, 30%, 36, 150, white, and ascending. Settings SHALL apply to every batch item and persist during additions, removals and selection changes. Initial output policy SHALL keep each input's format; explicit batch conversion choices SHALL persist independently of preview selection. Restart SHALL restore initial values and an empty batch. Existing watermark sizing rules SHALL remain unchanged; zoom SHALL NOT modify them. Saved presets and per-file overrides are outside this change.

#### Scenario: Adjust appearance
- **WHEN** the user expands adjustments and changes any supported setting
- **THEN** the selected preview and subsequent exports of every item reflect that setting without an additional Apply action

#### Scenario: Invisible or empty watermark
- **WHEN** the user supplies empty text or zero opacity
- **THEN** every preview and export contains no visible watermark and otherwise follows its effective output mode

#### Scenario: Selection preserves the shared configuration
- **WHEN** the user switches between a PDF, JPG and PNG after editing settings and choosing an output policy
- **THEN** watermark settings and output policy remain unchanged

### Requirement: Responsive and accurate preview
The preview SHALL update after input settles without blocking interaction and SHALL identify its file and, for PDFs, current page and total page count. Previous/next controls SHALL make every PDF page inspectable, disabling navigation at the first and last pages. Zoom-in, zoom-out and Fit to window SHALL be offered; zoomed content SHALL be scrollable. Selecting a different file SHALL start at its first page and Fit to window. Page changes SHALL preserve the chosen view mode. Preview content SHALL match the selected file, page, shared settings and effective export policy, including watermark size, direction, opacity, page geometry and the existing PDF-to-image 72-DPI output. Reduced resolution is allowed, but zoom MUST NOT present magnified obsolete or low-resolution imagery as a completed detailed preview when more output detail is available. Outdated background results MUST NOT replace newer state.

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

### Requirement: Recoverable failures and export feedback
The app SHALL explain unsupported, corrupt, protected, oversized, unreadable and unwritable items in plain language beside the affected row. Adding or selecting an invalid item MUST NOT remove other valid items or display another item's preview as its own. Processing SHALL show busy state, prevent overlapping export runs and report success only after a complete input's outputs are committed. Runs SHALL continue past individual failures and end with accurate saved, failed and unprocessed counts. Cancellation and write failure SHALL leave the remaining collection and shared settings usable for another attempt.

#### Scenario: Recover after an invalid document
- **WHEN** adding a corrupt file fails and the user subsequently adds or selects a valid file
- **THEN** the app recovers without restart and no stale document or preview is exported

#### Scenario: Cancel or fail an export
- **WHEN** the destination dialog is cancelled, the run is cancelled or output writing fails
- **THEN** the app reports no false success, keeps sources usable and permits another export attempt
