# Specification: Fix Missing Secure Mode for PDFs

## 1. Overview
Users report that the "Secure Mode" option is not visible when a PDF document is selected. This feature is critical for preventing watermark removal, as described in product requirements (v1.2).

## 2. Trigger Condition
- The user selects a PDF file using the file picker.

## 3. Functional Requirements
- **FR-1**: The "Secure Mode" toggle/checkbox must be visible when a PDF file is loaded.
- **FR-2**: The "Secure Mode" option must be functional (i.e., when enabled, it triggers the rasterization process).
- **FR-3**: The UI should update immediately upon file selection to show available options for the specific file type.

## 4. Non-Functional Requirements
- **NFR-1**: Fix must not regress existing image watermarking functionality.

## 5. Acceptance Criteria
- [ ] Load a PDF file -> "Secure Mode" option is visible.
- [ ] Load an Image file (JPG/PNG) -> "Secure Mode" option behavior remains consistent (hidden or disabled as per design for images).
- [ ] Enabling "Secure Mode" on a PDF results in a rasterized PDF output.

## 6. Out of Scope
- Changes to the actual rasterization algorithm (unless it's the root cause of the UI issue).
