## Purpose

Provide a simple native Mac workflow for opening one document, previewing a configurable watermark, and exporting a copy with all existing adjustments available.

## ADDED Requirements

### Requirement: Single-document native workflow
The app SHALL present a native macOS window with an Open action, watermark text, preview, and export controls. Less-used appearance adjustments SHALL be available in a collapsed-by-default expandable section. The app SHALL use native file and destination dialogs and process one document at a time.

#### Scenario: Open a document
- **WHEN** the user opens a supported image or PDF
- **THEN** the app displays the image or first PDF page with a watermark preview and enables applicable controls
- **AND** the PDF page count is visible and export covers every page

#### Scenario: Initial and cancelled selection
- **WHEN** the app has no loaded document or the user cancels the Open dialog
- **THEN** an empty app keeps export disabled, and cancellation leaves any existing valid document unchanged

### Requirement: Preserve watermark settings
The app SHALL offer text up to 200 characters, opacity 0–100%, size 12–72, spacing 50–300, white/black/gray color, and ascending/descending diagonal directions. Initial values SHALL remain COPY, 30%, 36, 150, white, and ascending. Settings SHALL persist while switching documents within the session, while export format SHALL reset to JPG for image input and PDF for PDF input. Restart SHALL restore initial values; saved presets are outside this change.

#### Scenario: Adjust appearance
- **WHEN** the user expands adjustments and changes any supported setting
- **THEN** the preview and subsequent export reflect that setting without an additional Apply action

#### Scenario: Invisible or empty watermark
- **WHEN** the user supplies empty text or zero opacity
- **THEN** preview and export contain no visible watermark and otherwise follow the chosen output mode

### Requirement: Flattened PDF default and clear mode choice
The initial PDF mode SHALL be flattened at 450 DPI, with 300 and 600 DPI also available. Standard PDF mode SHALL remain available and preserve selectable source text. The choice SHALL be visible when exporting PDF input as a PDF, and quality SHALL be shown when flattening applies. The interface SHALL explain that standard watermarks can be edited separately and flattened pages lose ordinary text selection. It MUST NOT claim flattening prevents all removal, editing, or OCR.

#### Scenario: First PDF export
- **WHEN** the user opens a PDF in a fresh session and exports without changing its mode
- **THEN** the app exports a flattened PDF at 450 DPI

#### Scenario: Choose standard output
- **WHEN** the user selects standard mode
- **THEN** the app explains watermark removability and retains ordinary selectable source text in exported PDFs

### Requirement: Responsive and accurate preview
The preview SHALL update after input settles without blocking interaction. It SHALL depict the current document and settings with equivalent watermark size, spacing, direction, color, and opacity to the final output. A reduced-resolution preview is allowed. PDF preview SHALL remain first-page-only in this change. Outdated background results MUST NOT replace newer state.

#### Scenario: Rapid changes and document replacement
- **WHEN** the user rapidly changes settings or opens a different file during preview generation
- **THEN** the final visible preview belongs to the latest document and settings
- **AND** export uses the latest settings rather than stale preview bytes

### Requirement: Recoverable failures and export feedback
The app SHALL explain unsupported, corrupt, protected, oversized, unreadable, and unwritable inputs or destinations in plain language. Failed replacement loads SHALL leave the prior valid document usable, or leave the initial empty state when none exists. Processing SHALL show a busy state, prevent overlapping exports, and report success only when output writing finishes.

#### Scenario: Recover after an invalid document
- **WHEN** opening a corrupt file fails and the user subsequently opens a valid file
- **THEN** the app recovers without restart and no stale document or preview is exported

#### Scenario: Cancel or fail an export
- **WHEN** the destination dialog is cancelled or output writing fails
- **THEN** the app reports no false success, keeps the source usable, and allows another export attempt
