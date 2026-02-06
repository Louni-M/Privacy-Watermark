# Plan: Flexible Export Format Selection

## Phase 1: Dynamic Export Format Dropdown [ ]

- [ ] Task: Write tests for dynamic dropdown options based on file type
  - [ ] Sub-task: Test that uploading an image sets dropdown options to JPG, PNG, PDF with JPG as default
  - [ ] Sub-task: Test that uploading a PDF sets dropdown options to PDF, Images (JPG), Images (PNG) with PDF as default
  - [ ] Sub-task: Test that dropdown is visible for both image and PDF uploads
  - [ ] Sub-task: Test that dropdown resets correctly when switching between file types

- [ ] Task: Implement dynamic dropdown options in `main.py`
  - [ ] Sub-task: Create a helper method to set dropdown options based on file type
  - [ ] Sub-task: Update `on_file_result()` to call the helper and show dropdown for images
  - [ ] Sub-task: Update PDF upload path to use new dropdown options (PDF, Images JPG, Images PNG)
  - [ ] Sub-task: Ensure dropdown visibility is set correctly for all file types (including error/unknown)

- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: PNG Export Support [ ]

- [ ] Task: Write tests for PNG export from image files
  - [ ] Sub-task: Test that selecting PNG format produces valid PNG output with watermark
  - [ ] Sub-task: Test that PNG output has metadata stripped
  - [ ] Sub-task: Test that save dialog uses correct extension and allowed_extensions for PNG

- [ ] Task: Implement PNG export for image files in `main.py` and processing code
  - [ ] Sub-task: Add PNG watermark generation function (or modify `apply_watermark` to support format parameter)
  - [ ] Sub-task: Update `on_save_button_click()` to handle PNG format selection
  - [ ] Sub-task: Update `on_save_result()` to write PNG output when selected

- [ ] Task: Write tests for PNG export from PDF pages
  - [ ] Sub-task: Test that selecting "Images (PNG)" exports each page as PNG
  - [ ] Sub-task: Test that PNG files follow naming convention `export_page_001.png`

- [ ] Task: Implement PNG export for PDF pages in `pdf_processing.py`
  - [ ] Sub-task: Add format parameter to `save_pdf_as_images()` to support PNG output
  - [ ] Sub-task: Update `on_save_button_click()` to use directory picker for Images (PNG)
  - [ ] Sub-task: Update `on_dir_result()` to pass format parameter when saving PDF as images

- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Image-to-PDF Conversion [ ]

- [ ] Task: Write tests for image-to-PDF conversion
  - [ ] Sub-task: Test that a watermarked image is correctly embedded into a single-page PDF
  - [ ] Sub-task: Test that PDF page dimensions match original image dimensions (in points)
  - [ ] Sub-task: Test that save dialog uses correct extension and allowed_extensions for PDF

- [ ] Task: Implement image-to-PDF conversion
  - [ ] Sub-task: Create `save_image_as_pdf()` function in `pdf_processing.py`
  - [ ] Sub-task: Update `on_save_button_click()` to handle PDF format for image files
  - [ ] Sub-task: Update `on_save_result()` to call `save_image_as_pdf()` when image→PDF is selected

- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Save Dialog Adaptation & Integration Testing [ ]

- [ ] Task: Write integration tests for save dialog behavior
  - [ ] Sub-task: Test that save dialog defaults match selected format for all combinations (image→JPG, image→PNG, image→PDF, PDF→PDF, PDF→Images JPG, PDF→Images PNG)
  - [ ] Sub-task: Test that existing export flows remain unaffected (backward compatibility)

- [ ] Task: Verify and fix save dialog adaptation across all export paths
  - [ ] Sub-task: Audit `on_save_button_click()` for correct `file_name`, `allowed_extensions`, and picker type per format
  - [ ] Sub-task: Fix any inconsistencies found during audit
  - [ ] Sub-task: Verify default format selections (JPG for images, PDF for PDFs)

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
