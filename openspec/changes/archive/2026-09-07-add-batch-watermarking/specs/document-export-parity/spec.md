## MODIFIED Requirements

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
