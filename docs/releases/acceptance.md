# DMG acceptance record

## v2.1.2 — published 2026-09-15

- Source: `47b5e6e367f601705ee13d541db469583aa42add`; tag: `v2.1.2`, verified to resolve to that exact commit.
- [Published latest release](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.1.2). Privacy-Watermark.dmg: **3,150,979 bytes** (3.15 MB).
- SHA-256: `ac329c2a4d7613a405e58c434724f0406fc61daf9be9492faadc81f70a6a233c`.
- Fixes repeated long/multiline watermark collisions using shared measured layout, keeps export/progress/cancellation visible while settings scroll, separates validation exclusions from attempted failures, and gates PDF controls on eligible output routes. README behavior and included installer button names match the app.
- **60 native tests in 16 suites** and **seven release-script tests** passed locally. Additional visual/native/processing runs covered default pixel compatibility, Unicode and whitespace extremes, preview/export parity, cancellation, and actual minimum-size light/dark layouts. Detailed evidence and remaining interaction checks are in [implementation acceptance](../../openspec/changes/improve-watermark-layout-and-export-clarity/acceptance.md).
- [Source CI](https://github.com/Louni-M/Privacy-Watermark/actions/runs/35000630087) passed on macOS 14 Apple Silicon and macOS 15 Intel, including native tests, universal builds and window/export smoke checks. [Security](https://github.com/Louni-M/Privacy-Watermark/actions/runs/35000630232) and [CodeQL](https://github.com/Louni-M/Privacy-Watermark/actions/runs/35000629284) passed for the same immutable source.
- [Final exact uploaded-DMG verification](https://github.com/Louni-M/Privacy-Watermark/actions/runs/35001719969) passed on both architectures. Both recorded hashes match the built/uploaded candidate. Both launch reports confirm a visible window after copy and eject. Finder screenshots were reviewed: app icon, Applications shortcut, arrow/instructions and Install.txt are all visible and readable.
- The [initial installer verification](https://github.com/Louni-M/Privacy-Watermark/actions/runs/35000802133) passed package and launch checks but its Intel screenshot captured an empty icon placeholder, including an Intel-only retry. Verification-only commit `d52b965ef9b7537598d2fa52f78f511871d1ee09` increased the Finder capture delay from 3 to 20 seconds. The final screenshots show the icon on both Macs. No app source or DMG changed; the release tag stays on the source commit above.
- Evidence is retained in workflow artifacts and ignored `.build/release-2.1.2-evidence/final/`. Initial and retry evidence is retained alongside it. Local packaging and verification logs are `.build/release-2.1.2-prepare.log` and `.build/release-2.1.2-local-verify.log`; downloaded draft/public images are under ignored `dist/release-2.1.2/`.
- The uploaded image was verified locally, mounted read-only and inspected in Finder, then ejected. The existing app session was preserved. Local navigation inherited Finder's list view; icon view was selected to inspect the artwork, while the hosted screenshots verify the saved standalone installer presentation.
- The stable public latest-download URL was downloaded **without authentication**. Its checksum matches the accepted candidate, the release is stable/latest and no longer a draft, and the public asset has the expected name and size.
- Fresh browser/Gatekeeper acceptance was not repeated. Physical trackpad gestures, a full VoiceOver session and fresh Finder drag-and-drop interaction remain manual follow-ups; automated checks are not represented as those observations. The release remains ad-hoc signed and not notarized.

## v2.1.1 — published 2026-09-12

- Source: 4b77e7474e797e76f2e05eee7ddf2effaec39b22; tag: v2.1.1.
- [Published release](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.1.1). Privacy-Watermark.dmg: 3,132,379 bytes.
- SHA-256: cef36a7a5c4d548a1880de134082122aeda7b84343272badd990ddecccda100f.
- App/module/installer branding is Privacy Watermark; the redundant upper-left title is removed. The app was visually verified locally using a fictional sample document.
- 55 native tests across 15 suites and seven release-script tests passed locally. [Source CI](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34685159830) passed on macOS 14 Apple Silicon and macOS 15 Intel, including universal builds and native window/export smoke checks. Security and CodeQL passed for the same source revision.
- [Exact uploaded-DMG verification](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34685203989) passed on both architectures. Both recorded hashes match; both launch reports confirm a visible window. Finder screenshots were reviewed and show the correct title, app, Applications shortcut, arrow, instructions and Install.txt. The image was also opened locally in Finder and ejected after review.
- Evidence is retained in workflow artifacts and locally under ignored .build/release-2.1.1-evidence/.
- The public latest-download URL was downloaded without authentication; its hash matches the uploaded candidate. The published tag resolves to the exact source revision above.
- Fresh browser/Gatekeeper acceptance was not repeated; automated checks are not represented as manual first-launch acceptance. The release remains ad-hoc signed and not notarized.
- The maintainer's Recordly project and original export are saved locally. The README includes a 1.14 MB looping preview without watch/download-video links; the full MP4 is retained as a repository asset. Playback of the exported demo was visually reviewed. Subsequent demo/documentation edits do not change the tagged app binary.


## v2.1.0 — published 2026-09-11

Published at the maintainer's request to commit, push, and release the latest workflow changes.

- Source: `a12b03819d828c6aa76a54f09054cdd5541e821a`; tag: `v2.1.0`.
- [Published release](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.1.0), with the universal `Passport-Filigrane.dmg` (3,131,447 bytes).
- DMG SHA-256: `6b7eeb05cc59f7874ca878fdaab42d2ea1663065990083c8ddf72eec1e262efb`.
- Local native tests: 55 tests in 15 suites passed; seven release-script tests passed.
- [Source CI](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34644569435) passed on macOS 14 Apple Silicon and macOS 15 Intel, including universal builds and native window/export smoke checks.
- [Exact uploaded-DMG verification](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34644620700) passed on both architectures: package, copy, eject, and installed launch with a visible window. Both Finder screenshots were reviewed and show readable app, Applications, and installation-help labels. Workflow artifacts retain hashes, screenshots, and launch reports; local copies are under ignored `.build/release-2.1.0-evidence/`.
- The anonymous public latest-download URL returned a DMG matching the uploaded candidate SHA-256. README links to the download and versioned release.
- Fresh browser/Gatekeeper acceptance was not performed for this release; automated installation checks are not represented as manual acceptance. Existing first-launch instructions remain applicable.

## v2.0.1 — published 2026-09-10

The maintainer requested completion and publication after the tagged draft was uploaded.

- Source: `ce30d9c19db1991229e8eab6fa960abac04c06e3`; tag: `v2.0.1`.
- [Published latest release](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.0.1).
- DMG SHA-256: `9132437262f23d0ae49c5f94d097adaec0c8c0f280732aaa9450702e000dde7d`.
- Native tests and seven release-script tests passed locally; [tagged-source CI](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34495529241) passed on both architectures.
- [Exact uploaded-DMG checks](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34525671383) passed on macOS 14 Apple Silicon and macOS 15 Intel: package verification, copy, eject, and installed launch with a visible window.
- Both Finder screenshots were reviewed: app, Applications shortcut, installation instructions, and Install.txt are visible and readable. Evidence is retained under [Apple Silicon](v2.0.1/macos-14/finder.png) and [Intel](v2.0.1/macos-15-intel/finder.png), alongside launch reports, hashes, and system versions.
- The public latest-download URL was downloaded without authentication and its SHA-256 matched the uploaded candidate.
- Fresh manual browser/Gatekeeper observations were not collected for this patch; automated checks are not represented as manual acceptance. Publication follows the maintainer's explicit instruction to finish the release.

## v2.0.0 historical acceptance

Status: **v2.0.0 published following maintainer first-launch acceptance**. Automated installation/runtime checks passed on both architectures; a separate manual Intel browser/Gatekeeper observation has not been recorded.

## Final candidate

- Date: 2026-09-08.
- App version: 2.0.0 (bundle build 1).
- Source: `07918eab138b5ab3bab23c141800f55af397bf33`.
- [Published release](https://github.com/Louni-M/Privacy-Watermark/releases/tag/v2.0.0).
- Local uploaded-asset copy: `dist/release-2.0.0/Passport-Filigrane.dmg` (2,952,563 bytes).
- SHA-256: `25b1f3f37fbe531ab25798c0ea0f94584644c7bc48554afa130e6ce826788893`.
- [Successful release build](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34257217679).
- [Successful uploaded-DMG verification on both Macs](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34257450336).

The earlier working-tree image and first draft are superseded. Screenshot review found the first draft's help label clipped; the final candidate increases the Finder window from 660 × 440 to 660 × 480 points. No published binary was replaced.

## Automated and visual evidence

| Check | Result |
| --- | --- |
| Release preparation | Passed: clean committed checkout, version validation, native tests, packaging and verification; draft created without publication |
| Release failure boundaries | Passed: 7 tests cover invalid version/revision, dirty checkout, existing draft/tag, API failure, failed tests/build/verification, and draft-only creation |
| Workflow/source validation | Passed: actionlint, YAML parsing, shell syntax, strict OpenSpec validation, whitespace checks |
| Final image | Passed: compressed read-only UDZO, valid checksum, matching uploaded hash on both test Macs and local download |
| Bundle | Passed: expected identity/icon, macOS 14 minimum, version 2.0.0, arm64 and x86_64 slices, strict ad-hoc signature |
| Contents | Passed: app, help, presentation resources and /Applications link; no runtime or source tree packaged |
| Finder presentation | Passed by screenshot review on both Macs: app, Applications, arrow, title, instructions and full Install.txt label visible together without overlap or clipping |
| Copy/eject/launch | Passed on both Macs: app copied from the exact downloaded image, image ejected, installed app launches and displays a window |
| Failure handling | Wrong expected version, existing output and truncated image rejected; no temporary verification mounts left attached |

| Test environment | Retained evidence |
| --- | --- |
| Apple Silicon, macOS 14.8.9 (23J631) | [Finder](macos-14/finder.png), [launch](macos-14/bundle-launch.json), [hash](macos-14/sha256.txt), [system](macos-14/system.txt), [native export smoke](macos-14/native-smoke.json) |
| Intel, macOS 15.7.9 (24G830) | [Finder](macos-15-intel/finder.png), [launch](macos-15-intel/bundle-launch.json), [hash](macos-15-intel/sha256.txt), [system](macos-15-intel/system.txt), [native export smoke](macos-15-intel/native-smoke.json) |

The broader Intel native suite exposed a pre-existing race in the preview retention test: visible-page completion does not imply neighbor prefetch completion. Test-only commit `c626830` waits for the selected page image and then asserts that zoom preserves that same image. The focused local regression passed. No app source changed. The full [native CI run](https://github.com/Louni-M/Privacy-Watermark/actions/runs/34257614167) passed on both macOS 14 Apple Silicon and macOS 15 Intel, including native behavior tests, universal builds, window checks and export/reopen smoke tests. No app source changed between the candidate revision and the test-only correction.

## Browser and first launch

The final candidate was subsequently downloaded through Safari as `Downloads/Passport-Filigrane-2.dmg`. Its SHA-256 matches the final uploaded asset and its quarantine metadata records Safari (`0083`). After providing the macOS warning screenshot and receiving the documented Done → Privacy & Security → Open Anyway steps, the maintainer confirmed “ok it works”. This records successful user acceptance of that first-launch flow; detailed manual export/reopen observations were not supplied separately.

On the local Apple Silicon Mac (macOS 26.6.2), Safari downloaded the first draft with normal quarantine metadata (`0083`, agent Safari). Its hash matched that uploaded asset. Finder copying preserved quarantine on the copied app. LaunchServices attempted opening it, and `spctl --assess` rejected it as expected for this distribution mode.

The agent cannot capture the local security prompt or operate its controls: local screen capture is unavailable and System Events reports that osascript is not allowed assistive access. The maintainer supplied the “Not Opened / Apple could not verify … is free of malware” warning and subsequently confirmed that the documented approval steps work. No quarantine attributes were removed and no Gatekeeper settings were disabled. The final candidate's visual and runtime checks above are complete; CLI download/direct launch is not browser/Gatekeeper acceptance.

## Release acceptance and coverage

- [x] Public destination resolved: the maintainer authorized making Louni-M/Privacy-Watermark public. GitHub reports PUBLIC; anonymous repository access returned HTTP 200.
- [x] Committed draft produced by the release workflow.
- [x] Final Finder screenshots reviewed and installed launch verified on both architectures.
- [x] Full native CI passes with the corrected preview test on both architectures.
- [x] Maintainer first-launch acceptance recorded after the documented per-app approval steps.
- [ ] Separate manual Intel browser/Gatekeeper and detailed manual export/reopen observations remain unrecorded. Both architectures have automated installation, launch and export/reopen evidence; this is not represented as manual browser coverage.
- [x] Published v2.0.0 as latest after maintainer acceptance, activated the README download link, and downloaded the public asset without authentication. Its SHA-256 exactly matches `25b1f3f37fbe531ab25798c0ea0f94584644c7bc48554afa130e6ce826788893`.

The release is public. The maintainer requested archival on 2026-09-08 with 14 of 15 tasks complete. [Archived OpenSpec task 5.3](../../openspec/changes/archive/2026-09-08-add-dmg-distribution/tasks.md) retains the broader manual-coverage follow-up; publication and archival do not turn missing observations into completed tests.
