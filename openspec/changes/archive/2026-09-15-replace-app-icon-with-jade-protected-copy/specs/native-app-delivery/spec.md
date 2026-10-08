## MODIFIED Requirements

### Requirement: Supported native application
Privacy Watermark SHALL run natively on macOS 14 or newer on Apple Silicon and Intel. A reproducible build SHALL produce a downloadable `Privacy Watermark.app` with the existing name and the jade Protected copy icon, requiring no separately installed Python or other language runtime. Documentation SHALL identify supported systems and accurately describe local installation and signing status.

#### Scenario: Install built application
- **WHEN** the built app is copied into Applications on a supported Mac
- **THEN** it launches and completes a local open-preview-export workflow without Python installed

#### Scenario: Recognize the application icon
- **WHEN** the application icon is displayed in Finder or the running app's Dock entry at small and large sizes
- **THEN** it shows the selected jade rounded square with an ivory document, folded corner, and protective offset corner
- **AND** the silhouette remains distinguishable at 16 and 32 points, with no comparison-board labels, mockup surroundings, clipped artwork, or opaque rectangular border outside the rounded square
- **AND** the app retains its existing name and bundle identity

### Requirement: Drag-to-Applications disk image
Distribution SHALL provide one DMG containing Privacy Watermark.app for macOS 14 or newer on both Apple Silicon and Intel. Its Finder window SHALL present the jade Protected copy app icon, an Applications shortcut, and a legible drag-to-install instruction in a deliberate layout without overlapping or clipped labels. Installation SHALL require no developer tools, terminal commands, additional runtime, or paid account from the user.

#### Scenario: Install a downloaded disk image
- **WHEN** a user opens the downloaded DMG on a supported Mac
- **THEN** the installation window shows the app and Applications destination together
- **AND** dragging the app to Applications installs a complete app that can be launched after ejecting the DMG and completing any macOS security approval

#### Scenario: Inspect the packaged app
- **WHEN** the release package is verified
- **THEN** the enclosed app has both supported architecture slices, the jade Protected copy icon and its existing application identity, a valid ad-hoc signature, and a version matching the release
