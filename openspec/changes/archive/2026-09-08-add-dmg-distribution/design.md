## Context

See proposal.md for motivation and scope. The existing scripts/build-app.sh builds both architectures, combines them with lipo, and ad-hoc signs the bundle. scripts/Info.plist holds the app version and macOS 14 minimum. CI already exercises native tests and the built app on Apple Silicon and Intel. The repository remote is Louni-M/Privacy-Watermark; no release workflow currently exists.

## Goals / Non-Goals

**Goals:** Reuse the existing build, provide consistent installation presentation, and separate preparing a candidate from publishing it. Keep packaging tooling on the maintainer/CI side.

**Non-Goals:** See proposal.md. No app data migration or app runtime changes are needed. A first-run wizard cannot solve a security prompt that occurs before the app opens.

## Decisions

### Package with macOS tools, dmgbuild, and checked-in presentation sources

Add a packaging script that calls the existing universal build, stages only the intended app, an /Applications symlink, an installation document, and presentation resources, then produces a compressed read-only DMG with hdiutil through dmgbuild. Use a controlled Finder layout with the existing icon on the left, Applications on the right, and a simple arrow/instruction. Generate presentation metadata during packaging; do not rely on a developer's personal Finder state. Verify the saved layout and background alias in the final image. Clean up temporary mounts on failure. Rebuild in an isolated output directory so stale app resources cannot leak into releases.

A ZIP is simpler to produce but misses the requested installation experience. A package installer adds complexity with no need for privileged installation. Finder automation did not respond in the implementation environment, so use the free dmgbuild 1.6.7 library with pinned dependencies in an isolated build-only Python environment. This writes Finder settings without Apple Events; none of these tools are shipped in the app or image. Do not set FinderInfo on the signed app to hide its extension: strict signature verification rejects that metadata.

### Use one stable download filename per release

Attach Passport-Filigrane.dmg to each versioned GitHub release. The README download target is https://github.com/Louni-M/Privacy-Watermark/releases/latest/download/Passport-Filigrane.dmg. Put macOS requirements and the first-launch caveat next to the link; include full steps in release notes and an offline readable Install.txt inside the image. Use English consistent with current documentation. Preserve the current app name/icon; detailed colors and spacing are implementation choices subject to visual acceptance.

Versioned release tags provide history while the asset name keeps the download URL stable. A separate website adds maintenance outside the agreed scope. Before the first publication, label the download as not yet available rather than presenting a broken link as usable; activate the public link as part of publication sequencing.

### Prepare drafts through manual workflow dispatch

Use a dedicated GitHub Actions workflow with an explicit version and immutable source revision, checking out that revision. Validate the requested version against the bundled Info.plist and reject an existing tag/release before mutations. Run existing native tests plus package integrity checks before creating the draft. Use the normal repository token with contents:write scoped to the release job; do not require Apple credentials or personal access tokens. Serialize release preparation to avoid conflicting attempts. Attach the DMG and notes containing the source commit and installation steps; never publish automatically. If attachment fails, report failure and leave any partial draft clearly incomplete for maintainer cleanup.

On 2026-09-08 the maintainer explicitly chose to make the existing source repository public. The visibility change is complete and anonymous access is verified. Use this same repository for DMG releases and standard macos-14 hosted execution; no separate download repository or cross-repository credentials are needed. Retain the workflow guard against private-repository execution in case visibility changes later. Local packaging remains available. Normal CI and source pushes do not create releases.

### Treat downloaded launch behavior as a release gate

Record package verification separately from browser-download acceptance. The maintainer downloads the attached draft asset through a browser and verifies normal quarantine handling on a fresh supported test environment without an existing approval for this app. Test Apple Silicon and Intel, covering macOS 14, and record exact prompts. Verify Finder layout, copying, ejecting, launch, and a synthetic open-preview-export workflow. CI launch tests alone do not exercise Gatekeeper's downloaded-app path.

Explain Apple's supported Open Anyway flow for unidentified-developer blocking, acknowledging that system policy or different errors can prevent it. Do not instruct users to clear quarantine with shell commands or disable Gatekeeper. If the proposed instructions do not work for the candidate, resolve the package/instructions and repeat acceptance before publication.

Sources: [Apple first-launch guidance](https://support.apple.com/en-au/102445), [Developer ID](https://developer.apple.com/developer-id/), [GitHub release links](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases). Verify current platform/tool details during implementation.

## Risks / Trade-offs

- Free ad-hoc distribution retains a first-launch trust hurdle → disclose it before download and test the actual procedure; do not promise frictionless opening.
- Finder presentation can differ across macOS versions → verify saved metadata automatically and visually inspect the final image on supported test Macs.
- Intel or a clean macOS 14 environment may be unavailable → leave the corresponding acceptance pending until a suitable Mac or test environment is available.
- Draft assets are accessible only to authorized reviewers → use the maintainer's browser for candidate tests; verify anonymous download immediately after publication.
- The first public DMG may not exist when documentation lands → inspect existing releases and coordinate activating the README download link with initial DMG publication.

## Migration Plan

1. Add packaging and verification, then the draft-only workflow and documentation.
2. Trigger a candidate build from a committed revision with a matching version; verify draft assets and perform the recorded installation checks.
3. The maintainer manually publishes after acceptance, activates the download link, and checks anonymous download access.
4. If a public artifact is defective, withdraw the affected download and update the README to explain availability; restore a previously accepted release if one exists. Never silently replace published binaries under an existing version.

No existing installed app or document requires migration. Updates remain outside this change.
