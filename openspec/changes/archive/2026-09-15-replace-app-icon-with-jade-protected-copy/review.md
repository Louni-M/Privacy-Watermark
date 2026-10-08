# Verification: replace-app-icon-with-jade-protected-copy

Date: 2026-09-15. Schema: spec-driven. Updated after approved corrective work.

| Dimension | Status |
|---|---|
| Completeness | 5/5 tasks complete; both requirements implemented |
| Correctness | Package, asset, export checks pass; Dock confirmed by user |
| Coherence | Selected design and stable ICNS pipeline retained |

## CRITICAL — resolve before archive

None. Task 2.2 is complete, including the user’s direct Dock confirmation.

## WARNING — should fix

None. Final installed-build export repeat now passes; see acceptance and final evidence.

## Resolved findings

- Task 2.1: ten correct ICNS representations, transparent corners, actual-pixel
  16-/32-point light/dark review, universal build, identity and signature checks
  pass. See `evidence/small-sizes.png` and master composites.
- Task 2.3: acceptance now records completed checks, limitations, platform, scope,
  and evidence. Its wording explicitly permits pending checks, so it is complete.
- Stray visible green/cyan perimeter pixels removed by user-approved alpha mask;
  all RGB artwork preserved. Light/dark composites show clean antialiasing.
- Final mounted installer capture was retaken after enlarging Finder so the
  complete Install.txt icon/label is visible. Finder renders a dark rounded
  backing around the jade artwork; source transparency is assessed separately
  through the composited asset evidence.
- Final mounted installer jade icon/layout and copy/eject/launch exercised using
  isolated `~/Applications/Jade Icon Verification`, preserving existing installation.

## Requirement and design mapping

- Supported native application: existing `scripts/build-app.sh:7–17` continues
  combining both slices, embedding ICNS/plist, and signing. `scripts/Info.plist:4–12`
  retains name, identifier, version and minimum OS. `assets/icon/generate.sh:7–15`
  derives all ten sizes from the retained master.
- Drag-to-Applications image: `scripts/dmg-settings.py:7–23` continues packaging
  app, Install.txt, Applications shortcut/background and placement. Integrated
  verification passes on final DMG (hash in acceptance). Install scenario at
  `specs/native-app-delivery/spec.md:19` now has local copy/eject/launch evidence;
  no release publication is within scope.
- No runtime source changes or new asset system. Icon generation remains macOS
  `sips`/`iconutil`; Pillow was used only for the expressly authorized one-time
  alpha cleanup, not as a build dependency.

## Assessment

Parent review independently confirmed the clean white composite, actual-size
light/dark samples, corrected complete installer capture, successful final-build
export screenshot, final app signature and both architectures, source/embedded
ICNS equality, and byte-identical regeneration from a temporary copy of the
generator. A 27-file baseline covering Swift sources, identity/version, README,
and unrelated pre-existing spec/release edits remained unchanged. `git diff
--check` passes. The Dock check was completed through direct user observation, not waived.

**No critical issues or warnings remain. Ready to archive and sync.**
All three review dimensions were assessed. The final installed app completed
open-preview-export, and the user confirmed the running Dock icon at normal and
enlarged sizes. Intel/macOS 14 runtime was not exercised; this coverage limit is
retained explicitly and is not inferred from universal binary validation.
Strict OpenSpec validation passes. See `acceptance.md` for evidence and scope.
