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

### Requirement: Drag-to-Applications disk image
Distribution SHALL provide one DMG containing Passport Filigrane.app for macOS 14 or newer on both Apple Silicon and Intel. Its Finder window SHALL present the existing app icon, an Applications shortcut, and a legible drag-to-install instruction in a deliberate layout without overlapping or clipped labels. Installation SHALL require no developer tools, terminal commands, additional runtime, or paid account from the user.

#### Scenario: Install a downloaded disk image
- **WHEN** a user opens the downloaded DMG on a supported Mac
- **THEN** the installation window shows the app and Applications destination together
- **AND** dragging the app to Applications installs a complete app that can be launched after ejecting the DMG and completing any macOS security approval

#### Scenario: Inspect the packaged app
- **WHEN** the release package is verified
- **THEN** the enclosed app has both supported architecture slices, its existing icon and identity, a valid ad-hoc signature, and a version matching the release

### Requirement: Discoverable download and first-launch guidance
The README SHALL prominently provide Download for Mac access to the published DMG, supported systems, and concise installation instructions. The release page and a readable document inside the DMG SHALL explain copying to Applications, ejecting the disk image, and opening the installed app. Guidance SHALL disclose that the app is ad-hoc signed and not notarized and describe the applicable macOS Privacy & Security approval flow without requiring terminal commands or disabling Gatekeeper globally.

#### Scenario: Find the installer
- **WHEN** a visitor reads the top of the README after the initial release is published
- **THEN** the Download for Mac link downloads the DMG from GitHub Releases without requiring source-code navigation or a GitHub account
- **AND** macOS 14 or newer and Intel/Apple Silicon compatibility are visible nearby

#### Scenario: macOS blocks first launch
- **WHEN** macOS blocks the downloaded app because its developer cannot be verified
- **THEN** the user can read the installation guidance before successfully launching the app
- **AND** the guidance describes the supported per-app approval procedure and does not claim the app is Apple-verified

#### Scenario: Approval is unavailable
- **WHEN** the expected approval control is unavailable or the Mac reports a different blocking condition
- **THEN** the guidance distinguishes this from the normal installation flow and directs the user to troubleshooting or their Mac administrator without instructing them to remove system protections

### Requirement: Deliberate draft-release preparation
A maintainer-triggered release process SHALL build and verify the universal app and DMG from an identified source revision and prepare a draft GitHub release with installation guidance and its DMG attached. It SHALL verify agreement between the requested release version and packaged app version. It SHALL NOT publish automatically, overwrite a published release, or replace the public download with an unverified package. Release preparation SHALL require no paid services or Apple signing credentials.

#### Scenario: Prepare a release candidate
- **WHEN** the maintainer triggers preparation for a valid version and revision and all required automated checks pass
- **THEN** a draft release is prepared with the DMG, version, source revision, and installation instructions available for review
- **AND** existing public downloads remain unchanged until the maintainer publishes

#### Scenario: Reject an invalid release candidate
- **WHEN** version validation, build, tests, signature, architecture, or DMG verification fails
- **THEN** preparation reports failure and does not present the candidate as ready for publication

#### Scenario: Repeat preparation
- **WHEN** preparation is triggered for an existing release tag
- **THEN** it fails clearly without overwriting that release or its assets

### Requirement: Downloaded installation acceptance
Release acceptance SHALL include automated package checks and recorded manual verification of the actual candidate obtained through a browser download with normal macOS quarantine behavior. Evidence SHALL identify the candidate version and revision, macOS version, processor architecture, Finder presentation, first-launch prompts and recovery, and a successful synthetic document watermark export from the installed app after ejecting the DMG. Both supported processor families SHALL receive installation and runtime verification before the initial public release; cross-compilation alone SHALL NOT count as runtime evidence. Unperformed checks SHALL remain explicitly pending.

#### Scenario: Approve the first public DMG
- **WHEN** the maintainer assesses the initial release candidate
- **THEN** evidence covers the downloaded installation flow on Apple Silicon and Intel, including macOS 14 coverage, and the exported document reopens correctly with its source unchanged
- **AND** any failed or missing required check prevents the candidate from being marked ready for publication
