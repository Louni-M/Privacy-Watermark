# document-export-parity Specification

## Purpose

Preserve the document conversion, watermark, privacy, and validation behavior of Privacy Watermark while replacing its processing implementation with native macOS code.

## Requirements

### Requirement: Complete format matrix
The app SHALL accept case-insensitive .jpg, .jpeg, .png and .pdf extensions and validate actual readability. Image input SHALL export as JPG, PNG or a single-page PDF. PDF input SHALL export as standard PDF, flattened PDF or one JPG or PNG file per page. Every PDF page SHALL be exported in order with its visible content and orientation preserved. A batch SHALL resolve its shared Keep original format/PDF/JPG/PNG policy independently for each input; the initial policy SHALL retain PDF, JPG and PNG respectively. Inputs SHALL NOT be merged.

#### Scenario: Image export matrix
- **WHEN** each supported image type is exported in each offered format
- **THEN** the output is readable in that format, preserves image dimensions and contains the configured watermark
- **AND** an image-to-PDF output has one page with image pixel dimensions mapped to PDF points, matching the existing behavior

#### Scenario: PDF image export
- **WHEN** a multipage PDF is exported to JPG or PNG
- **THEN** its pages are written to a dedicated uniquely named `<source-stem>_watermarked` folder inside the selected destination as `<source-stem>_page_001.jpg` or `.png`, increasing in order
- **AND** output uses the existing 72-DPI page sizing, with mode-specific watermark appearance preserved

#### Scenario: Output format changes after preview
- **WHEN** the user switches the batch policy from JPG to PNG and exports before another preview completes
- **THEN** image destinations contain genuine PNG data, not previously generated JPEG bytes

### Requirement: Equivalent watermark and output quality
Watermarks SHALL repeat diagonally across the full image or every PDF page and honor all settings. Text size and spacing SHALL be proportional to the shorter displayed document side, with reference length 210 / 25.4 * 72 points. At that reference length, configured size SHALL retain its existing numerical meaning. Configured spacing SHALL be the requested minimum repetition pitch; the app SHALL increase effective horizontal and vertical separation as needed to keep the complete rotated text blocks apart with visible breathing room. The complete watermark pattern geometry SHALL scale consistently, independently of source pixel density, output format, rasterization DPI, and preview zoom. Minor font metrics and antialiasing differences are acceptable; missing text, reversed direction, materially different opacity or inconsistent normalized geometry across equivalent documents, clipped document content, and degraded readability are not. PNG output SHALL be lossless for the rendered image; JPEG quality SHALL be visually comparable to the current quality-90 output and quality-95 flattened PDF images. Existing opaque image output behavior SHALL be retained; transparency preservation is not a new capability.

Watermark text SHALL preserve explicit line breaks as repeated multiline blocks in the selected direction across previews and all image, standard PDF, and flattened PDF output routes. Lines SHALL retain input order and consistent line spacing, without automatic wrapping or automatic font-size changes. Existing single-line text whose repeated blocks already have sufficient clearance SHALL retain its prior normalized geometry. Patterns that collide SHALL use the automatic minimum separation. Mode-specific opacity SHALL remain unchanged. Blank text and zero opacity SHALL continue to produce no visible watermark without warnings or export restrictions. The 200-character limit SHALL include line breaks.


Repeated blocks SHALL NOT collide for any accepted text and appearance settings. Explicit blank lines and Unicode glyph extents SHALL be included in spacing decisions. Each line within a block SHALL also have adequate baseline separation for its rendered glyphs. Text SHALL NOT be silently shortened, wrapped, or reduced in size to achieve separation. Document edges MAY clip stamps as before; a visible nonempty watermark SHALL NOT disappear solely because adaptive spacing exceeds the page size. When a complete block fits within the displayed page, at least one complete block SHALL be placed on the page. Geometry SHALL be stable during panning and zooming and deterministic from the full document geometry and shared settings.


#### Scenario: Representative visual comparison
- **WHEN** reference images and PDFs are rendered with both directions, all colors, and representative settings including boundaries
- **THEN** native outputs retain the normalized watermark coverage and document readability under side-by-side review, with existing mode-specific opacity preserved

#### Scenario: Equivalent document at different resolutions
- **WHEN** the same document geometry is supplied as an A4 PDF and as JPG and PNG images at multiple resolutions with identical settings
- **THEN** text height and pattern spacing relative to the shorter side match in fitted previews and reopened exports, allowing font rasterization and encoding differences
- **AND** image pixel dimensions and PDF page geometry remain unchanged

#### Scenario: Every output route uses the same geometry
- **WHEN** an image is exported as JPG, PNG, or PDF, or a PDF is exported as standard PDF, flattened PDF at 300/450/600 DPI, or page images
- **THEN** relative watermark text size, spacing, direction, and pattern placement agree with that route's preview
- **AND** the existing output resolution, mode-specific opacity, and standard/flattened PDF text semantics remain intact

#### Scenario: Rotated and mixed-size pages
- **WHEN** a PDF contains portrait, landscape, cropped, and differently sized pages
- **THEN** each page uses its own displayed shorter side and places the normalized watermark over its full visible area
- **AND** partial preview regions agree with the corresponding area in the full exported page

#### Scenario: Multiline preview and export parity
- **WHEN** two or more explicit text lines are applied to JPG, PNG and multipage PDF sources and exported through each supported route
- **THEN** previews and reopened outputs contain the same ordered lines in repeated diagonal blocks with matching relative size, spacing, direction, and route-specific opacity
- **AND** standard PDF watermark text remains extractable while flattened output retains its existing text-layer behavior

#### Scenario: Existing single-line and invisible output
- **WHEN** existing single-line settings, blank text, or zero opacity are rendered
- **THEN** non-overlapping single-line output retains its existing appearance and invisible settings produce unmarked copies without warnings, confirmations, or additional restrictions

#### Scenario: Rental purpose with name and date
- **WHEN** the text contains `For rental application`, `Élodie — Zürich`, and a date on separate lines with default size and spacing
- **THEN** neighboring repeated blocks remain visibly separated in the sample, selected preview, and reopened outputs
- **AND** each block preserves the three lines, their order, and selected text size

#### Scenario: Large text and minimum spacing
- **WHEN** accepted long single-line or multiline text is rendered at size 72 and spacing 50 in either direction
- **THEN** automatic minimum separation prevents intersections between neighboring blocks without changing the entered settings
- **AND** increasing requested spacing never decreases effective separation

#### Scenario: Blank lines and document-edge clipping
- **WHEN** accepted text includes many blank lines, emoji, or accented characters and the block is larger than the page
- **THEN** rendering remains bounded and shows nonempty watermark content where possible, with edge clipping rather than silent wrapping or shrinking
- **AND** lines and neighboring repeated blocks remain separated

### Requirement: Standard PDF semantics
Standard output SHALL preserve selectable source text and vector content without flattening the whole page. The watermark SHALL remain vector text that is present after saving and reopening, and selectable/extractable by a PDF text reader. Page count, displayed page geometry, and visible document content SHALL be preserved.

#### Scenario: Reopen standard PDF
- **WHEN** a PDF containing text and vector graphics is exported in standard mode and reopened independently
- **THEN** original text and watermark text can be extracted, vector content remains sharp when enlarged, and every page displays the watermark

### Requirement: Flattened PDF semantics
Flattened output SHALL render every page with its watermark at the selected 300, 450, or 600 DPI and embed the combined result into a new PDF of the same displayed page dimensions. The output MUST NOT contain a separate watermark layer or an embedded selectable text layer from the source or watermark. OCR performed later by another application is outside this guarantee.

#### Scenario: All flattening qualities
- **WHEN** a multipage document is exported at each supported DPI
- **THEN** page image dimensions correspond to the chosen DPI, watermark proportions remain consistent, and ordinary PDF text extraction returns no source or watermark text

### Requirement: Local processing and image metadata removal
Documents SHALL be processed locally without network uploads, accounts, or telemetry. Exported JPG/PNG files and images embedded in newly generated image or flattened PDFs MUST NOT carry source EXIF, GPS, camera, or timestamp metadata. This SHALL NOT be presented as a general sanitization guarantee for existing standard PDFs. Diagnostics MUST NOT record document contents or watermark text; any file log SHALL retain owner-only access and sanitization of home paths and control characters.

#### Scenario: Metadata-bearing photo
- **WHEN** a photo containing EXIF and GPS data is exported through each image output route
- **THEN** the exported image data contains no copied source metadata and remains readable

#### Scenario: Offline use
- **WHEN** the Mac has no network connection
- **THEN** opening, previewing, and exporting supported local files remains functional

### Requirement: Preserve validation boundaries
The app SHALL reject files larger than 100 MiB, PDFs exceeding 50 pages, images exceeding 20,000 pixels on either side, password-protected PDFs, PDFs with no pages, and corrupt or unsupported files. Exact size and count boundaries SHALL remain accepted for otherwise valid inputs. Validation SHALL occur before expensive full rendering where possible. Allocation or rendering failures SHALL produce recoverable errors.

#### Scenario: Limit boundaries
- **WHEN** otherwise valid inputs are exactly at or just above each configured limit
- **THEN** boundary inputs are accepted and over-limit inputs receive a specific error without exporting stale state

#### Scenario: Protected or empty PDF
- **WHEN** a password-protected or zero-page PDF is selected
- **THEN** the app explains why it cannot open the document without starting a password workflow

### Requirement: Repeatable exports and source preservation
Previewing and exporting MUST NOT change any batch source or accumulate watermark content in it. Each run SHALL apply its captured shared settings once to validated source content. Export SHALL use native destination-folder selection and `<source-stem>_watermarked` names, with numeric suffixes for conflicts. Every batch source and every pre-existing destination SHALL be protected from replacement, including resolved source identities. Failed or cancelled input writes SHALL remove only incomplete outputs created for that input; earlier completed inputs SHALL remain. A page-image series SHALL be committed as a complete unit. Rerunning SHALL create new numbered copies rather than overwriting previous exports.

#### Scenario: Export twice with changed text
- **WHEN** the user exports the batch with text A and then exports with text B
- **THEN** the second set of copies contains only watermark B, earlier copies remain and source files remain byte-for-byte unchanged

#### Scenario: Destination conflict or partial failure
- **WHEN** a destination already exists or a page-series export fails after some pages are prepared
- **THEN** existing files are not overwritten, no partial output is reported as success and temporary artifacts for the failed input are cleaned up

#### Scenario: One source resembles another output name
- **WHEN** a batch contains `passport.pdf` and a separate source named `passport_watermarked.pdf` in the destination folder
- **THEN** exporting the first input chooses an unused name and neither source is changed
