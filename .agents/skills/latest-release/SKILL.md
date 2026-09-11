---
name: latest-release
description: Commit and push the latest Passport Filigrane changes, build and verify a universal macOS DMG, publish a new tagged GitHub release, and update README download links and release evidence. Use when the user asks to ship, publish, or release the latest changes, including committing and pushing them with a DMG release.
---

# Latest release

Run this workflow from this repository's root. This skill is project-local: keep its files under `.agents/skills/latest-release/`. It may be selected implicitly for a matching release request. Skill selection alone does not authorize publication: follow the user's requested scope. When the user requests the full release, complete it without asking for repeated confirmation; honor a draft-only request.

## 1. Inspect and choose the version

- Follow the repository's AGENTS.md and use graft before source searches. Reuse context already gathered in the current task.
- Inspect `git status --short`, the branch, remotes, pending diff (including untracked files), recent commits, and `gh release list`. Fetch origin and check divergence before committing. Preserve unrelated changes and never force-push or silently overwrite existing releases.
- Confirm the intended destination is `Louni-M/Privacy-Watermark`, currently reached through `origin`, and check authenticated GitHub access. Do not change repository visibility or authentication scopes.
- Read the current release instructions and acceptance record in `docs/releases/`, the version in `scripts/Info.plist`, and the release/verification workflows as needed. Prefer the existing scripts over reimplementing them.
- Use a requested version, otherwise choose the next appropriate unused semantic version: minor for new compatible features, patch for fixes. Announce the choice. Check both tags and releases, including drafts; an API failure does not establish that a version is unused.
- Set `CFBundleShortVersionString` in `scripts/Info.plist`. Update the root `README.md` version and versioned release link, retaining this stable download URL:
  `https://github.com/Louni-M/Privacy-Watermark/releases/latest/download/Passport-Filigrane.dmg`.
  Do not carry forward an old DMG size as if measured for the new release.

## 2. Test, commit, and push source

- Run `git diff --check`, `scripts/test.sh`, and `python3 scripts/test-release.py`. Run other checks required by the actual changes; reuse valid evidence from this session when appropriate. Resolve failures before publication.
- Review and stage all intended changes, including new source files, tests, documentation, and completed OpenSpec artifacts. Do not commit credentials, build products, or temporary evidence. Refresh graft after substantial code changes if it has not already been refreshed.
- Commit the release source and version with a descriptive message, then push the intended branch (normally `main`). Avoid an empty commit if already committed.
- Record the full immutable source SHA with `git rev-parse HEAD`. The checkout must be clean and that commit must be present remotely. The eventual tag must resolve to this exact revision.

## 3. Build and upload a draft

Run the existing release preparation script with the chosen version (without `v`) and full source SHA:

```sh
python3 scripts/prepare-release.py "$release_version" "$release_revision" --check-only
python3 scripts/prepare-release.py "$release_version" "$release_revision"
```

The script validates the checkout and unused version, runs native tests, builds in a fresh ignored directory, verifies the DMG, calculates SHA-256, and uploads an unconditional draft against the exact source revision. Packaging must verify the compressed UDZO image, contents, layout metadata, app identity/version/icon, macOS minimum, arm64 and x86_64 slices, and strict ad-hoc signature.

If packaging tools are missing, install the pinned dependencies into `.build/dmg-tools` as documented in `docs/releases/README.md`. If local packaging is unavailable, dispatch `.github/workflows/release.yml` with the same version and immutable revision, and wait for successful completion. Do not build or upload a stale DMG.

Inspect the draft's tag, target, body, assets, state, byte size, and digest. Download `Passport-Filigrane.dmg` into a fresh ignored `dist/release-<version>/` directory and independently compare its SHA-256 with the built/uploaded digest. A partial or failed upload remains an unpublished draft; investigate it rather than blindly retrying creation or replacing an asset.

## 4. Verify the exact uploaded installer

- Dispatch `gh workflow run verify-dmg-release.yml -f tag="$release_tag"` where the tag is `v<version>`. Identify the run for this dispatch, not an unrelated recent run.
- Wait for both macOS 14 Apple Silicon and macOS 15 Intel jobs to pass. They download the exact draft asset, verify it, capture Finder, copy the app, eject the image, and launch the installed app with a visible window.
- Download the workflow evidence into ignored `.build/release-<version>-evidence/`. Compare hashes and inspect both launch reports and Finder screenshots. Confirm the app, Applications shortcut, arrow/instructions, and Install.txt are visible and readable. Use the visual-verification skill and computer use for a local installer check when available; eject mounts opened for review and preserve the user's existing app session.
- Wait for source CI for the recorded release SHA to finish successfully on both architectures, including tests, universal builds, and native window/export smoke checks. Inspect other required checks as well. Track exact run IDs and URLs; do not mistake a different commit's green run for this release.
- Poll with reasonable intervals and keep the user informed without narrating unchanged results. Resolve actionable failures and repeat only affected verification. If app source changes, create a new clean source commit and rebuild/reverify the candidate against it; never publish evidence for an older binary as evidence for the new one.
- Automated CLI installation checks do not establish fresh browser/Gatekeeper acceptance. Record missing manual observations honestly. A full maintainer release request authorizes publication after the checks above without another confirmation, as in the v2.1.0 workflow. Never remove quarantine or weaken system security to manufacture acceptance.

## 5. Publish and verify public delivery

- Write final release notes to an ignored or temporary file. Summarize the actual changes; include macOS/architecture requirements, full source SHA, DMG SHA-256, and current installation/first-launch guidance from `assets/dmg/Install.txt`. Align button names with the released UI. Retain the ad-hoc signing/notarization disclosure. Remove the draft's candidate-only wording without inventing manual acceptance.
- Publish the verified draft as stable/latest using a body file, not shell-interpolated multiline prose:

```sh
gh release edit "$release_tag" --draft=false --latest --notes-file "$release_notes_path"
```

- Download the public `releases/latest/download/Passport-Filigrane.dmg` URL without authentication into a separate file and verify its SHA-256 matches the accepted candidate. Confirm the release is no longer a draft, is latest, contains the uploaded asset, and has the intended tag. Fetch the tag and verify its resolved commit equals the recorded source SHA.
- Never silently replace binaries under an already published version. If public delivery fails, investigate and correct it explicitly; do not report completion prematurely.

## 6. Finish documentation and report

- Update root `README.md` with the measured download size, versioned release link, and stable latest-DMG link.
- Update current availability in `docs/releases/README.md` and prepend a dated entry in `docs/releases/acceptance.md`: source SHA/tag, public release URL, exact byte size and SHA-256, test results, source-CI and uploaded-DMG run links, screenshot/launch observations, evidence locations, public hash verification, and any manual acceptance gaps.
- Commit and push these final documentation changes. Keep the release tag on the tested source commit; the later documentation commit does not require retagging or rebuilding the unchanged app.
- Verify the branch is synchronized with origin and no task changes remain uncommitted. If unrelated changes were preserved, state that instead of claiming a clean checkout.
- Respond concisely with the published release link, confirmation of commit/push and README update, validation results, and any material limitation. Include the required graft savings tally when graft was used.
