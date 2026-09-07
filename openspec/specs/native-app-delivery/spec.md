# native-app-delivery Specification

## Purpose

Deliver a maintainable native Mac application with verified compatibility, document parity, and performance, and retire the old implementation after the replacement passes acceptance.

## Requirements

### Requirement: Supported native application
Passport Filigrane SHALL run natively on macOS 14 or newer on Apple Silicon and Intel. A reproducible build SHALL produce a downloadable `Passport Filigrane.app` with the existing name and icon, requiring no separately installed Python or other language runtime. Documentation SHALL identify supported systems and accurately describe local installation and signing status.

#### Scenario: Install built application
- **WHEN** the built app is copied into Applications on a supported Mac
- **THEN** it launches and completes a local open-preview-export workflow without Python installed

### Requirement: Behavioral acceptance evidence
Migration acceptance SHALL include automated checks and visual review for the complete format matrix, every PDF mode and DPI, settings, metadata removal, validation, recovery, repeated exports, and preservation of originals. Evidence SHALL use synthetic non-sensitive fixtures and include reopen checks in an independent viewer. Compatibility evidence SHALL distinguish actual runtime checks from cross-compilation; untested support MUST NOT be reported as verified.

#### Scenario: Parity review
- **WHEN** the replacement is assessed for completion
- **THEN** a recorded checklist links each behavior to tests or review evidence, with no required check silently skipped

### Requirement: Measured performance improvement
On the same Mac and representative synthetic fixtures, the native release app SHALL launch and update previews measurably faster than the current packaged Python app and SHALL have no material export slowdown. Measurements SHALL use identical inputs, watermark settings, and processing modes, including an explicit flattened-450-DPI comparison rather than comparing different defaults. The report SHALL record hardware, OS, build settings, methodology, repeated timings, and peak memory observations.

#### Scenario: Compare implementations
- **WHEN** launch, preview changes, and exports are measured repeatedly under comparable conditions
- **THEN** the report demonstrates faster launch and preview results beyond run-to-run noise and evaluates export regressions against the documented threshold
- **AND** any unmet performance gate remains unfinished work rather than being excused by the native implementation

### Requirement: Mandatory legacy retirement
The old implementation SHALL remain available for comparison until parity, compatibility, and performance acceptance passes. Afterwards the migration MUST remove legacy Python application code, runtime/development dependency manifests, PyInstaller packaging, obsolete tests, and temporary comparison code. Native tests, CI, build instructions, and security documentation SHALL replace their legacy equivalents. Useful synthetic fixtures, recorded measurements, and version history SHALL be retained without maintaining two applications.

#### Scenario: Final cleanup gate
- **WHEN** native acceptance has passed
- **THEN** the repository builds and tests the native app alone, active instructions contain no Python launch or packaging steps, and runtime bundles contain no Flet, Pillow, PyMuPDF, or Python dependency
- **AND** the migration remains incomplete until this cleanup and a clean native build/test check have finished
