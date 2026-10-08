## MODIFIED Requirements

### Requirement: Frozen export run with isolated failures
Starting export SHALL capture the current ordered eligible items and shared settings. Collection and setting changes SHALL be disabled until the run ends; preview selection and navigation SHALL remain available. A failed file SHALL receive a readable row error and MUST NOT prevent remaining files from being attempted. Completion SHALL distinguish successfully committed source documents, eligible items whose attempted export failed, inputs excluded because validation had already failed, and eligible items not processed or interrupted by cancellation. An item with failed validation SHALL be excluded from attempts and retain its visible validation error, without incrementing the run’s failed count. Each source in the frozen run SHALL belong to exactly one outcome category; saved + failed + excluded + unprocessed SHALL equal the frozen source count. Progress SHALL continue to count only eligible documents. A source that becomes unavailable after eligibility is captured SHALL count as failed for that run, and as excluded on a later run if it remains invalid. Export SHALL be disabled while initial validation is pending or no valid item exists. Another run SHALL be possible after failure or cancellation without restarting the app.

#### Scenario: Mid-batch write failure
- **WHEN** one input fails during writing after another has succeeded
- **THEN** the successful output remains, the failed input has no partial visible output, and remaining eligible inputs are attempted
- **AND** the summary never reports the failed input as saved

#### Scenario: All candidates invalid
- **WHEN** every imported candidate fails validation
- **THEN** each failure is visible and export stays disabled
- **AND** adding a valid file restores the ability to export after validation

#### Scenario: Validation exclusions are not export failures
- **WHEN** three valid and three invalid inputs are submitted and all valid outputs commit
- **THEN** the result contains three saved, zero failed, three excluded, and zero unprocessed
- **AND** the excluded inputs are never attempted and all original row errors remain visible

#### Scenario: Cancellation with excluded files
- **WHEN** a run contains three eligible inputs and two validation exclusions, saves one input, and is then cancelled before any other input commits
- **THEN** the summary reports one saved, zero failed, two excluded, two unprocessed, and cancellation
- **AND** only committed outputs remain and all five source documents stay accounted for

#### Scenario: Source changes after the run starts
- **WHEN** an eligible source becomes unreadable before its export attempt
- **THEN** that attempt counts as failed exactly once, other eligible inputs continue, and its row explains the source problem
- **AND** a later run excludes the still-invalid source without double-counting it as failed
