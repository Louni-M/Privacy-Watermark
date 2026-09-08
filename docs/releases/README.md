# DMG packaging and releases

The installer contains one universal native app for macOS 14 or newer, an Applications shortcut, and offline installation help. Python and the packaging libraries run only on the build Mac; they are not shipped to users. The app remains ad-hoc signed and is not notarized.

## Current availability

On 2026-09-08, the maintainer authorized making `Louni-M/Privacy-Watermark` public. Visibility is now public and anonymous repository access was verified (HTTP 200). This repository is the download destination. Its latest existing release remains `v1.4.1`, containing the older ZIP; do not activate the DMG download link until the first accepted DMG release is published.

The release workflow targets the public source repository. It retains a private-repository guard to avoid potentially billable hosted minutes if visibility changes in future. The selected standard `macos-14` runner is free under [GitHub's Actions billing rules](https://docs.github.com/en/billing/concepts/product-billing/github-actions). No billing or token-scope changes are needed. Local packaging remains available as a fallback.

## Build locally

Use a Mac with Swift 6 / Xcode 16 or compatible Command Line Tools, Python 3.10 or newer, and network access for the initial packaging-tool installation:

```sh
python3 -m venv .build/dmg-tools
.build/dmg-tools/bin/pip install -r scripts/dmg-requirements.txt
scripts/build-dmg.sh
```

The result is `dist/Passport-Filigrane.dmg`. To keep multiple candidates, choose an empty output directory:

```sh
OUTPUT_DIR='dist/candidate 2.0.0' scripts/build-dmg.sh
scripts/verify-dmg.sh 'dist/candidate 2.0.0/Passport-Filigrane.dmg' 2.0.0
```

Packaging refuses to overwrite an existing DMG. It builds the app in an isolated temporary staging directory, generates the artwork and Finder settings with pinned `dmgbuild` dependencies, compresses with macOS disk-image tools, and verifies the final mounted image. It requires no Finder automation permission. Build and verification failures do not produce a successful output; temporary verification mounts are ejected on failure. If macOS prevents ejecting, the script reports the mount and leaves its directory intact for manual ejection.

Verification checks the UDZO format, layout/background reference, root contents, Applications link, installation help, app icon/identity/version, macOS minimum, both binary architectures, and strict ad-hoc signature. Finder's actual presentation and downloaded-app security behavior still need the manual checks below.

## Prepare a draft

Release from a clean committed checkout, including packaging files and the intended app changes. Set `CFBundleShortVersionString` in `scripts/Info.plist` to the intended `MAJOR.MINOR.PATCH` version before committing. Use an unused `vMAJOR.MINOR.PATCH` tag. Existing tags or releases, including drafts, are rejected; inspect and clean up an incomplete draft manually before retrying.

Once the workflow is committed to the default branch on GitHub, choose **Actions → Prepare DMG release → Run workflow**, and enter the app version and full 40-character source commit SHA. The workflow checks out that exact revision, runs native and release tests, builds/verifies a fresh DMG, and prepares a **draft** with installation notes and a SHA-256 digest. It never publishes automatically.

Then run **Actions → Verify uploaded DMG** with the draft tag. It downloads that exact asset on macOS 14 Apple Silicon and macOS 15 Intel, verifies its package, captures the Finder window, copies/ejects/launches the app, and retains screenshots, hashes and launch reports as workflow artifacts. GitHub requires repository write permission to read an unpublished draft; this verification workflow uses it only for reading, never for publication. These CLI-download checks do not replace browser/Gatekeeper acceptance.

For the equivalent local process, authenticate the GitHub CLI with the maintainer account and run from a clean checkout whose commit is present in the destination repository:

```sh
python3 scripts/test-release.py
python3 scripts/prepare-release.py 2.0.0 FULL_40_CHARACTER_SOURCE_COMMIT_SHA --check-only
python3 scripts/prepare-release.py 2.0.0 FULL_40_CHARACTER_SOURCE_COMMIT_SHA
```

The destination is `Louni-M/Privacy-Watermark`; the target source commit must be pushed there before preparing its draft.

If using the GitHub web interface instead, run native tests, build and verify from the same clean commit, then create a new **draft** release against that commit. Attach `Passport-Filigrane.dmg`, include the exact source revision and SHA-256 from `shasum -a 256`, and copy `assets/dmg/Install.txt` into its notes. Label it a candidate awaiting manual acceptance. A failed upload leaves an incomplete draft, which is not ready to publish.

## Accept and publish

Use [the acceptance record](acceptance.md) for each candidate. Download the draft asset through a browser as an authorized reviewer; preserve normal macOS quarantine behavior. On fresh Intel and Apple Silicon test environments, including macOS 14 coverage:

1. Open the DMG and inspect the complete Finder window. Check readable labels, arrow, background, app icon, Applications link, and help document; capture a screenshot.
2. Drag the app into Applications, wait for copying, eject the DMG, and open the installed app.
3. Record the actual first-launch alerts. Follow the included per-app Privacy & Security approval instructions. Never clear quarantine or globally disable Gatekeeper to make the check pass.
4. Open a synthetic image/PDF, preview and export a watermark, then reopen the output independently and confirm the source stayed unchanged.

Mark missing environments or unresolved failures pending. A successful local launch without quarantine does not satisfy the downloaded-install check. First-launch instructions follow [Apple's guidance](https://support.apple.com/en-au/102445); managed Macs or different warnings can require administrator assistance.

Only after acceptance, the maintainer manually publishes the draft as a stable latest release. Activate the README Download for Mac link to `https://github.com/Louni-M/Privacy-Watermark/releases/latest/download/Passport-Filigrane.dmg` using the agreed public destination, and verify it in a signed-out browser. Check the downloaded hash against the accepted candidate. Keeping this asset filename unchanged makes the link stable between releases ([GitHub release links](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)).

If a defective public artifact must be withdrawn, mark the README download unavailable and withdraw the affected release deliberately. Restore a previously accepted latest release if one exists. Never silently replace binaries under an already published version. Updates and onboarding are outside this change.
