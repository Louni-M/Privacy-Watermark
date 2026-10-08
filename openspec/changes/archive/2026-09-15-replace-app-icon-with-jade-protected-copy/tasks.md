## 1. Prepare the selected icon

- [x] 1.1 Create a standalone 1024 × 1024 RGBA master for concept C in `assets/icon/`, preserving its jade and ivory protected-document design; compare it with the selected prototype and remove presentation elements.
- [x] 1.2 Generate the standard 1×/2× macOS iconset representations and replace `assets/app_icon.icns`; retain the master, provenance, and repeatable generation instructions.

## 2. Verify integration and presentation

- [x] 2.1 Inspect generated sizes, alpha corners, and 16-/32-point readability on light and dark backgrounds; build the universal app and verify its embedded ICNS matches the source while name, bundle identity, architectures, and signature remain valid.
- [x] 2.2 Build and verify a local DMG; inspect Finder, the running app's Dock icon, and the mounted installer for the jade icon and intact installation layout, then complete one synthetic open-preview-export smoke check.
- [x] 2.3 Record build/package results and visual evidence in `acceptance.md`, explicitly naming platform coverage and pending checks; confirm the change contains no version bump, published release change, or runtime behavior edits.
