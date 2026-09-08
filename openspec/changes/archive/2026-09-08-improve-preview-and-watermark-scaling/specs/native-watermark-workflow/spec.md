## MODIFIED Requirements

### Requirement: Preserve watermark settings
The app SHALL offer shared text up to 200 characters, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL remain COPY, 30%, 36, 150, white, and ascending. Settings SHALL apply to every batch item and persist during additions, removals and selection changes. Initial output policy SHALL keep each input's format; explicit batch conversion choices SHALL persist independently of preview selection. Restart SHALL restore initial values and an empty batch. Watermark size and spacing SHALL scale with the shorter displayed side of each image or PDF page, using an A4 shorter side (210 mm at 72 points per inch) as the reference. The same settings SHALL produce equal relative text size and spacing regardless of source resolution or type; zoom SHALL NOT modify them. Saved presets and per-file overrides are outside this change.

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

## ADDED Requirements

### Requirement: Readable selected filename
The selected filename SHALL appear in a full-width row above the preview controls, wrap to at most two lines, and expose the complete filename on hover and to accessibility tools. Names exceeding two lines SHALL truncate without overlapping controls. The row SHALL update with selection and clear when no file is selected.

#### Scenario: Long filename at minimum window size
- **WHEN** the user selects a file whose name exceeds the old toolbar space at the minimum supported window size
- **THEN** the header uses the available preview width and up to two lines without obscuring navigation
- **AND** the complete name is available on hover and through accessibility
