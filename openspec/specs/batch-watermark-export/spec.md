# batch-watermark-export Specification

## Purpose

Let users collect mixed images and PDFs, watermark them together with shared settings, and export safely named copies with clear progress and isolated failures.

## Requirements

### Requirement: Appendable mixed-file batch
The app SHALL accept multiple local JPG/JPEG, PNG and PDF files through a native Add files dialog and drag-and-drop. New additions SHALL append to the session without replacing existing items or shared settings. The app SHALL offer individual removal and Clear all. Directories and non-file drops SHALL NOT be recursively imported. Each candidate SHALL receive validation feedback; invalid candidates SHALL remain identifiable without preventing valid files from being used. Restart SHALL begin an empty batch.

#### Scenario: Gather files from several locations
- **WHEN** a user adds a PDF and JPG, then drops a PNG from another folder
- **THEN** all three appear in one batch with the same shared settings
- **AND** removing one item leaves the other two available

#### Scenario: Invalid item among valid files
- **WHEN** an addition includes a corrupt, protected, unsupported or over-limit file
- **THEN** its row explains the failure while other valid items remain usable
- **AND** cancelling the Add files dialog leaves the batch unchanged

#### Scenario: Clear the collection
- **WHEN** the user clears the idle batch
- **THEN** all items and previews disappear, export becomes disabled, and shared settings remain until restart

### Requirement: File identity determines duplicate additions
The same underlying file SHALL appear at most once, including repeated drops and resolved filesystem links to that file. Different files with identical names or identical contents SHALL remain distinct. Duplicate additions SHALL leave the existing row and settings intact and report that the item was already added.

#### Scenario: Duplicate and distinct same-name files
- **WHEN** a user adds an existing file again and also adds a different folder's file with the same name
- **THEN** the repeated file is ignored and the distinct file is retained

### Requirement: Shared batch output policy
The initial output policy SHALL be Keep original format: PDF to PDF, PNG to PNG, and JPG/JPEG to JPG. The app SHALL also offer one batch-wide conversion choice of PDF, JPG or PNG. Selection changes and later additions MUST NOT reset that policy. Each input SHALL remain independent; image-to-PDF exports SHALL NOT merge inputs. All PDFs SHALL share the existing flattened/standard mode and 300/450/600-DPI choice, initially flattened at 450 DPI. Watermark controls SHALL explicitly apply to all files, with no per-file overrides.

#### Scenario: Mixed default export
- **WHEN** a PDF, JPG and PNG are exported without changing defaults
- **THEN** the results are a flattened 450-DPI PDF, a JPG, and a PNG respectively

#### Scenario: Convert the batch
- **WHEN** the user selects PDF for a batch containing two images and one PDF
- **THEN** three independent PDFs are produced using the shared watermark
- **AND** selecting another preview does not change the output policy

### Requirement: One destination with collision-safe names
Export SHALL use one native destination-folder selection for all eligible files, including a batch of one. Single-file outputs SHALL use `<source-stem>_watermarked.<effective-extension>`. PDF-to-image output SHALL use a dedicated `<source-stem>_watermarked` folder containing `<source-stem>_page_001.jpg` or `.png` and subsequent pages in order. Existing or already reserved names SHALL gain ` (2)`, ` (3)` and so on before the extension or at the end of the folder name. Matching names MUST NOT cause replacement of an existing file, directory or any batch source. Conflicts appearing during export SHALL be resolved without overwriting another item.

#### Scenario: Repeated names and repeated export
- **WHEN** two distinct `passport.pdf` inputs are exported beside an existing `passport_watermarked.pdf`
- **THEN** newly saved outputs use available numbered names and the existing file is unchanged
- **AND** running the batch again creates additional copies without replacing previous results

#### Scenario: PDF pages stay together
- **WHEN** two multipage PDFs are converted to PNG
- **THEN** each receives its own uniquely named folder with correctly ordered page files
- **AND** an existing same-name folder is neither merged into nor overwritten

### Requirement: Frozen export run with isolated failures
Starting export SHALL capture the current ordered eligible items and shared settings. Collection and setting changes SHALL be disabled until the run ends; preview selection and navigation SHALL remain available. A failed file SHALL receive a readable row error and MUST NOT prevent remaining files from being attempted. Completion SHALL distinguish successfully committed source documents, failed items and items not processed. An item with failed validation SHALL be excluded from attempts and remain visibly failed. Export SHALL be disabled while initial validation is pending or no valid item exists. Another run SHALL be possible after failure or cancellation without restarting the app.

#### Scenario: Mid-batch write failure
- **WHEN** one input fails during writing after another has succeeded
- **THEN** the successful output remains, the failed input has no partial visible output, and remaining eligible inputs are attempted
- **AND** the summary never reports the failed input as saved

#### Scenario: All candidates invalid
- **WHEN** every imported candidate fails validation
- **THEN** each failure is visible and export stays disabled
- **AND** adding a valid file restores the ability to export after validation

### Requirement: File progress and cooperative cancellation
The app SHALL show progress by source document, for example “7 of 40 files”, and offer Cancel while export runs. Cancellation SHALL acknowledge the request promptly, stop before another input begins, preserve completed copies and discard the current uncommitted input's outputs. A PDF's page-image series SHALL be one completion unit: unfinished series MUST NOT remain as a partly exported folder. Inputs not attempted after cancellation SHALL remain available and SHALL NOT be labelled successful or failed. Cancellation SHALL take effect at safe processing boundaries; a file committed before cancellation took effect SHALL remain a completed file.

#### Scenario: Cancel a page series
- **WHEN** cancellation is requested while preparing a PDF's page images
- **THEN** earlier completed documents remain saved, the unfinished page-series folder is removed, and later documents are not started

#### Scenario: Cancel destination selection
- **WHEN** the user cancels the destination dialog
- **THEN** no output is written, no run begins, and no success is reported

### Requirement: Large-batch responsiveness and private source handling
The batch SHALL preserve macOS 14 Apple Silicon/Intel support, local-only processing, existing per-file validation limits and source/metadata protections. Acceptance SHALL exercise 100 distinct mixed inputs using the repeatable corpus and measurements in the design; 100 SHALL NOT be imposed as a hard item-count limit. Adding more files MUST NOT require retaining every source's fully decoded pixels or rendering every PDF page in advance. Changed, missing or newly unreadable sources SHALL receive an actionable error instead of silently exporting content inconsistent with a validated preview. Retained diagnostics and test evidence MUST NOT expose private document or watermark contents.

#### Scenario: Inspect and export 100 mixed files
- **WHEN** a 100-file batch is validated, browsed, edited and exported
- **THEN** interaction remains responsive, outputs correspond to the shared settings, and bounded-memory behavior is demonstrated against the recorded smaller-batch baseline

#### Scenario: Source changes on disk
- **WHEN** a validated source is changed or removed externally before it is loaded again for preview or export
- **THEN** that item is marked as needing re-addition or as unavailable, with no stale preview presented as current and no silent replacement content exported
