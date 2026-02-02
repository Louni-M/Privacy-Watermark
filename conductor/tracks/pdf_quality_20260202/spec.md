# Spec: PDF Quality Preservation with Native Vector Watermark

## Overview

Currently, the PDF watermarking process degrades document quality significantly because:
1. PDF pages are rendered at 72 DPI (low screen resolution)
2. Each page is converted to JPEG with lossy compression (quality=90)
3. The watermark is applied as a raster image overlay, flattening the original vector content

This makes watermarked documents unsuitable for official use (e.g., passports, identity documents) where sharpness and legibility are critical.

**Solution:** Replace the raster-based watermarking with native PDF vector watermarks using PyMuPDF's drawing APIs. This preserves the original PDF quality completely—text and graphics remain sharp at any zoom level.

## Functional Requirements

### FR-1: Native Vector Watermark Rendering
- The watermark text must be drawn directly onto PDF pages using PyMuPDF's native text/shape APIs (`page.insert_text()` or shape drawing methods)
- The watermark must appear as a diagonal tiled pattern (45° rotation) matching the current visual style
- The watermark must be added as an **overlay layer** on top of existing content

### FR-2: Preserve Existing Watermark Controls
The following user-adjustable parameters must continue to work:
- **Text**: Custom watermark text (default: "COPIE")
- **Opacity**: 0-100% (default: 30%)
- **Font size**: 12-72px (default: 36px)
- **Spacing**: 50-300px (default: 150px)
- **Color**: White, Black, or Gray (default: White)

### FR-3: Original PDF Quality Preservation
- The original PDF content (text, vectors, images) must NOT be rasterized
- Text in the original document must remain searchable/selectable
- The output file size should be comparable to or smaller than the original (no JPEG bloat)

### FR-4: Preview Compatibility
- The preview in the UI may continue using the existing raster approach (acceptable for display purposes)
- Alternatively, the preview can reflect the new vector watermark if feasible

### FR-5: Backward Compatibility
- Image files (JPG, PNG) must continue to work with the existing raster watermark approach
- No changes to the image processing pipeline

## Non-Functional Requirements

### NFR-1: Performance
- Watermarking a 10-page PDF should complete in under 5 seconds
- No noticeable UI lag during processing

### NFR-2: File Size
- Output PDF size should not exceed 110% of original file size (excluding watermark overhead)

## Acceptance Criteria

1. **AC-1**: Open a high-resolution PDF, apply watermark, save. Zoom to 400% — text in original document remains perfectly sharp (not pixelated).
2. **AC-2**: Text in the watermarked PDF remains selectable and searchable.
3. **AC-3**: All existing watermark controls (opacity, size, spacing, color) produce the expected visual result.
4. **AC-4**: File size of watermarked PDF is within 110% of original.
5. **AC-5**: Existing image watermarking (JPG/PNG) continues to work unchanged.

## Out of Scope

- Adding new watermark customization options (colors, angles, fonts)
- Watermark removal or editing features
- PDF password protection or encryption
- Multi-page preview navigation improvements
