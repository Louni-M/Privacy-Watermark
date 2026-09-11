## MODIFIED Requirements

### Requirement: Equivalent watermark and output quality
Watermarks SHALL repeat diagonally across the full image or every PDF page and honor all settings. Text size and spacing SHALL be proportional to the shorter displayed document side, with reference length 210 / 25.4 * 72 points. At that reference length, configured size and spacing SHALL retain their existing numerical meaning. The complete watermark pattern geometry SHALL scale consistently, independently of source pixel density, output format, rasterization DPI, and preview zoom. Minor font metrics and antialiasing differences are acceptable; missing text, reversed direction, materially different opacity or deviation from the normalized density, clipped document content, and degraded readability are not. PNG output SHALL be lossless for the rendered image; JPEG quality SHALL be visually comparable to the current quality-90 output and quality-95 flattened PDF images. Existing opaque image output behavior SHALL be retained; transparency preservation is not a new capability.

Watermark text SHALL preserve explicit line breaks as repeated multiline blocks in the selected direction across previews and all image, standard PDF, and flattened PDF output routes. Lines SHALL retain input order and consistent line spacing, without automatic wrapping or automatic font-size changes. Existing single-line text SHALL retain its prior normalized geometry and mode-specific opacity. Blank text and zero opacity SHALL continue to produce no visible watermark without warnings or export restrictions. The 200-character limit SHALL include line breaks.

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
- **THEN** single-line output retains its existing appearance and invisible settings produce unmarked copies without warnings, confirmations, or additional restrictions
