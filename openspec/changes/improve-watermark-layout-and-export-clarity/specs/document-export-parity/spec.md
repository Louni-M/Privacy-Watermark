## MODIFIED Requirements

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
