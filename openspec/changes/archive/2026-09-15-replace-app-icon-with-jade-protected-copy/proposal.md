## Why

The current ornate icon does not match the simpler identity the maintainer wants for Privacy Watermark. The maintainer selected concept C, “Protected copy,” in jade and ivory; this change turns that preview into the application icon.

## What Changes

- Replace the existing icon with a standalone rendering of the selected jade rounded square and ivory document with a folded corner and protective offset corner.
- Retain a production master and repeatable generation instructions for the macOS icon sizes, then replace the bundled ICNS asset.
- Verify the new icon in the built app, Finder, Dock, and a locally built DMG, including small-size readability and transparent outer corners.
- Preserve the app name, bundle identifier, supported platforms, watermark behavior, and installation flow. Publishing a release and refreshing historical demos are outside this change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `native-app-delivery`: Replace references to the existing icon with the selected jade Protected copy identity and require consistent, readable packaged icon presentation.

## Impact

The expected implementation touches icon assets and their generation documentation. `scripts/build-app.sh` already copies `assets/app_icon.icns`; `scripts/Info.plist` references `app_icon`, and `scripts/dmg-settings.py` uses that bundled resource for the disk image icon. These paths can stay stable. No runtime dependency or Swift behavior change is required.

The approved visual reference is concept C in `assets/icon-prototype/concepts.png` on local branch `codex/minimal-icon-prototype`, commit `3e4516b` (working copy: `.build/icon-prototype-worktree/assets/icon-prototype/`). The comparison board is a design reference, not an installable icon.
