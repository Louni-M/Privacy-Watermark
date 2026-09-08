## Why

The documented installation currently requires building the app with developer tools. Non-technical Mac users need a ready-to-download package with a familiar, professional drag-to-Applications installation experience, at no monetary cost to the project.

## What Changes

- Package the existing universal app in a polished DMG with the app icon, an Applications shortcut, and clear installation guidance.
- Put a prominent Download for Mac link and supported-system information at the top of the README, backed by GitHub Releases.
- Explain first-launch macOS security approval before users open the app, accurately identifying the ad-hoc signing and lack of notarization.
- Add a manually triggered process that builds and verifies a DMG and prepares a draft release; the maintainer tests installation before publishing manually.
- Record real downloaded-install acceptance evidence, including first launch and a watermark export.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `native-app-delivery`: Add downloadable DMG installation, discoverability, draft-release preparation, and downloaded-install acceptance requirements.

## Impact

Changes affect packaging scripts and presentation assets, GitHub release automation, README installation guidance, and release verification documentation. The existing native app, macOS 14 minimum, Intel and Apple Silicon support, local processing, and export behavior remain intact. No paid signing account, hosted service, or additional end-user runtime is required.

## Non-goals

App updates or update checks, an in-app welcome guide or setup wizard, a dedicated website, paid Developer ID signing/notarization, App Store distribution, and changes to watermarking behavior are separate changes.
