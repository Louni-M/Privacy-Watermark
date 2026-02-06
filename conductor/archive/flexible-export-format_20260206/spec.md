# Spec: Flexible Export Format Selection

## Overview

Currently, the application's export behavior is rigid:
- **Image files (JPG/JPEG/PNG):** Always export as JPEG — no format choice.
- **PDF files:** Can export as PDF or Images (JPG) — no PNG option.

This feature introduces a unified, context-aware export format selector that adapts its options based on the uploaded file type, enabling cross-format exports (e.g., image → PDF, PDF → PNG images).

## Functional Requirements

### FR-1: Dynamic Export Format Dropdown for Images
- When an image file (JPG, JPEG, PNG) is uploaded, the existing `export_format_dropdown` must become **visible** with the following options:
  - **JPG** (default) — Export as JPEG (quality 90), current behavior.
  - **PNG** — Export as lossless PNG.
  - **PDF** — Convert the watermarked image into a single-page PDF document.

### FR-2: Extended Export Format Dropdown for PDFs
- When a PDF file is uploaded, the existing `export_format_dropdown` must display:
  - **PDF** (default) — Export as PDF, current behavior (vector or secure mode).
  - **Images (JPG)** — Export each page as JPEG, current behavior.
  - **Images (PNG)** — Export each page as lossless PNG.

### FR-3: Image-to-PDF Conversion
- When the user selects "PDF" as export format for an image file:
  - The watermarked image is embedded into a single-page PDF.
  - The PDF page dimensions match the original image dimensions (in points, 72 DPI).
  - The image is embedded at its full resolution (no resampling).
  - The save dialog must default to `.pdf` extension with `allowed_extensions=["pdf"]`.

### FR-4: PNG Export for Images
- When the user selects "PNG" as export format for an image file:
  - The watermarked image is saved as lossless PNG.
  - Metadata is stripped (same as current JPEG behavior).
  - The save dialog must default to `.png` extension with `allowed_extensions=["png"]`.

### FR-5: PNG Export for PDF Pages
- When the user selects "Images (PNG)" for a PDF file:
  - Each page is exported as a lossless PNG file (instead of JPEG).
  - File naming follows existing convention: `export_page_001.png`, `export_page_002.png`, etc.
  - The directory picker is used (same as current "Images (JPG)" flow).

### FR-6: Save Dialog Adapts to Selected Format
- The save button click handler must read the selected export format and:
  - Set the correct `file_name` default (e.g., `export_filigree.jpg`, `.png`, or `.pdf`).
  - Set the correct `allowed_extensions`.
  - Use `save_file_picker` for single-file exports (JPG, PNG, PDF).
  - Use `save_dir_picker` for multi-file exports (Images JPG, Images PNG from PDF).

## Non-Functional Requirements

- **No new dependencies:** All required functionality is available via Pillow and PyMuPDF.
- **Performance:** PNG export may be slower/larger than JPEG — this is acceptable and expected.
- **Backward compatibility:** Default export formats remain unchanged (JPG for images, PDF for PDFs).

## Acceptance Criteria

1. Uploading a JPG/JPEG/PNG shows the export format dropdown with options: JPG, PNG, PDF.
2. Uploading a PDF shows the export format dropdown with options: PDF, Images (JPG), Images (PNG).
3. Selecting "PNG" for an image file produces a valid PNG output with watermark applied.
4. Selecting "PDF" for an image file produces a valid single-page PDF with the watermarked image embedded.
5. Selecting "Images (PNG)" for a PDF file produces one PNG per page in the selected directory.
6. The save dialog file name and allowed extensions match the selected export format.
7. Default selections remain JPG for images and PDF for PDFs (no change in default behavior).
8. All existing export flows (image→JPG, PDF→PDF, PDF→Images JPG) continue to work as before.

## Out of Scope

- Batch processing of multiple files.
- Converting multiple images into a multi-page PDF.
- DPI/quality selection for image-to-PDF conversion.
- SVG or other vector format exports.
- Changing the preview rendering (preview remains as-is).
