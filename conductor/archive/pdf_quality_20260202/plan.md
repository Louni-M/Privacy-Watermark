# Plan: PDF Quality Preservation with Native Vector Watermark

## Phase 1: Research & Foundation [checkpoint: 46b95d4]

- [x] Task: Investigate PyMuPDF vector text/shape APIs for watermark rendering [82feab7]
  - [x] Sub-task: Study `page.insert_text()` with rotation parameters
  - [x] Sub-task: Study `page.draw_*()` shape methods as alternative
  - [x] Sub-task: Test opacity/transparency support in PyMuPDF text rendering
  - [x] Sub-task: Document findings and chosen approach

- [x] Task: Create test PDF fixtures for quality validation [45c8ea2]
  - [x] Sub-task: Create a multi-page test PDF with text, vectors, and images
  - [x] Sub-task: Create a high-resolution test PDF for zoom testing

- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md) [46b95d4]

## Phase 2: Core Vector Watermark Implementation (TDD) [checkpoint: d2df448]

- [x] Task: Write failing tests for vector watermark function [467c8b1]
  - [x] Sub-task: Test that watermark text is added to PDF page
  - [x] Sub-task: Test that watermark respects opacity parameter
  - [x] Sub-task: Test that watermark respects font size parameter
  - [x] Sub-task: Test that watermark respects spacing parameter
  - [x] Sub-task: Test that watermark respects color parameter (White, Black, Gray)
  - [x] Sub-task: Test diagonal tiling pattern (45° rotation)

- [x] Task: Implement `apply_vector_watermark_to_pdf()` function [318cfeb]
  - [x] Sub-task: Create function signature matching existing parameters
  - [x] Sub-task: Implement diagonal text placement algorithm using PyMuPDF
  - [x] Sub-task: Implement opacity mapping to PDF transparency
  - [x] Sub-task: Implement color mapping (White, Black, Gray to RGB)
  - [x] Sub-task: Ensure watermark is added as overlay layer

- [x] Task: Verify all tests pass (Green phase) [318cfeb]

- [x] Task: Refactor for code clarity and performance [3af775e]

- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md) [d2df448]

## Phase 3: Integration & Migration [checkpoint: 036d171]

- [x] Task: Write failing tests for PDF processing integration [5b302e4]
  - [x] Sub-task: Test that original PDF text remains selectable after watermarking
  - [x] Sub-task: Test that original PDF quality is preserved (no rasterization)
  - [x] Sub-task: Test file size remains within 110% of original

- [x] Task: Integrate vector watermark into PDF save workflow [8b15589]
  - [x] Sub-task: Update `apply_watermark_to_pdf()` to use new vector function
  - [x] Sub-task: Preserve existing raster path for image files (JPG/PNG)
  - [x] Sub-task: Update `save_watermarked_pdf()` if needed

- [x] Task: Verify all tests pass (Green phase) [8b15589]

- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md) [036d171]

## Phase 4: Preview & Polish [checkpoint: 600e155]

- [x] Task: Evaluate preview rendering approach
  - [x] Sub-task: Determine if vector watermark can be shown in preview
  - [x] Sub-task: If not feasible, document that preview uses raster approximation

- [x] Task: Write tests for edge cases
  - [x] Sub-task: Test with encrypted/password-protected PDF (should fail gracefully)
  - [x] Sub-task: Test with very large PDF (10+ pages)
  - [x] Sub-task: Test with PDF containing only images (scanned document)

- [x] Task: Implement edge case handling

- [ ] Task: Performance optimization
  - [ ] Sub-task: Measure watermarking time for 10-page PDF
  - [ ] Sub-task: Optimize if exceeds 5 second target

- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md) [600e155]

## Phase 5: Final Validation

- [x] Task: Run full test suite with coverage report
  - [x] Sub-task: Ensure >80% coverage on new code
  - [x] Sub-task: Ensure all existing tests still pass

- [x] Task: Manual acceptance testing
  - [x] Sub-task: AC-1: Verify 400% zoom sharpness on real PDF
  - [x] Sub-task: AC-2: Verify text remains selectable
  - [x] Sub-task: AC-3: Verify all watermark controls work correctly
  - [x] Sub-task: AC-4: Verify file size constraint
  - [x] Sub-task: AC-5: Verify image watermarking unchanged

- [x] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)
