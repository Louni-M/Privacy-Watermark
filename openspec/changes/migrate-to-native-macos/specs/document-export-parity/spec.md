## Purpose

Preserve the document conversion, watermark, privacy, and validation behavior of Passport Filigrane while replacing its processing implementation with native macOS code.

## ADDED Requirements

### Requirement: Complete format matrix
The app SHALL accept case-insensitive .jpg, .jpeg, .png, and .pdf extensions and validate actual readability. Image input SHALL export as JPG, PNG, or a single-page PDF. PDF input SHALL export as standard PDF, flattened PDF, or one JPG or PNG file per page. Every PDF page SHALL be exported in order with its visible content and orientation preserved.

#### Scenario: Image export matrix
- **WHEN** each supported image type is exported in each offered format
- **THEN** the output is readable in that format, preserves image dimensions, and contains the configured watermark
- **AND** an image-to-PDF output has one page with image pixel dimensions mapped to PDF points, matching the existing behavior

#### Scenario: PDF image export
- **WHEN** a multipage PDF is exported to JPG or PNG
- **THEN** each page is written to the selected directory as `<source-stem>_page_001.jpg` or `.png`, increasing the number in order
- **AND** output uses the existing 72 DPI page sizing, with mode-specific watermark appearance preserved

#### Scenario: Output format changes after preview
- **WHEN** the user switches from JPG to PNG and exports before another preview completes
- **THEN** the destination contains genuine PNG data, not previously generated JPEG bytes

### Requirement: Equivalent watermark and output quality
Watermarks SHALL repeat diagonally across the full image or every PDF page and honor all settings. Minor font metrics and antialiasing differences are acceptable; missing text, reversed direction, materially different opacity or density, clipped document content, and degraded readability are not. PNG output SHALL be lossless for the rendered image; JPEG quality SHALL be visually comparable to the current quality-90 output and quality-95 flattened PDF images. Existing opaque image output behavior SHALL be retained; transparency preservation is not a new capability.

#### Scenario: Representative visual comparison
- **WHEN** reference images and PDFs are rendered with both directions, all colors, and representative settings including boundaries
- **THEN** native outputs retain equivalent watermark coverage and document readability under side-by-side review

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
Previewing and exporting MUST NOT change the source file or accumulate watermark content in the loaded source. Each export SHALL apply the latest settings once to the unchanged source. Export SHALL use native destination selection, preserve the `export_filigree` default basename for individual outputs, require confirmation before replacing existing destination files, and refuse a destination that resolves to the source itself. Failed writes SHALL remove incomplete outputs created by that operation without deleting pre-existing files.

#### Scenario: Export twice with changed text
- **WHEN** the user exports with text A and then exports with text B
- **THEN** the second output contains only watermark B and the source file remains byte-for-byte unchanged

#### Scenario: Destination conflict or partial failure
- **WHEN** a destination already exists or a page-series export fails after some pages are prepared
- **THEN** existing files are not silently overwritten, no partial output is reported as success, and temporary artifacts are cleaned up
