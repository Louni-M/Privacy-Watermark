# DMG acceptance record

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
