# Track Plan: Hybrid PDF Watermarking (Vector vs Secure Raster)

## Phase 1: UI Implementation
- [x] Task: Add `secure_mode_switch` to the sidebar controls. [f99a1b2]
- [x] Task: Add `dpi_segmented_button` with options [300, 450, 600]. [f99a1b2]
- [x] Task: Implement conditional visibility logic for DPI button. [f99a1b2]
- [x] Task: Conductor - User Manual Verification 'Phase 1'

## Phase 2: Core Logic - High-DPI Rasterization
- [x] Task: Implement `apply_secure_raster_watermark_to_pdf` in `pdf_processing.py`. [a1b2c3d]
- [x] Task: Optimize PyMuPDF `get_pixmap` usage for high resolutions (matrix/dpi). [a1b2c3d]
- [x] Task: Ensure watermark tiling is applied correctly at high resolution. [a1b2c3d]
- [x] Task: Conductor - User Manual Verification 'Phase 2'

## Phase 3: Integration & Preview
- [x] Task: Update `update_preview` to reflect secure mode (low-res raster preview). [e9a2b3c]
- [x] Task: Update `on_save_result` to branch between vector and secure-raster logic. [done]
- [x] Task: Fix DPI selection visibility and sidebar scrolling. [f8a9b0c]
- [x] Task: Conductor - User Manual Verification 'Phase 3'

## Phase 4: Final Validation
- [x] Task: Re-package the application to reflect recent changes (`flet pack`). [2783f89]
- [x] Task: Verify watermark permanence (attempt extraction). [verified]
- [x] Task: Verify file size/quality trade-offs at 300, 450, 600 DPI. [verified]
- [x] Task: Conductor - User Manual Verification 'Phase 4'
- [x] Task: Archive track [done]
