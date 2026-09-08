# DMG acceptance record

Status: **local candidate verified; not approved for public release**.

## Candidate

- Date: 2026-09-08.
- App version: 2.0.0 (bundle build 1).
- Local file: `dist/dmg candidate/Passport-Filigrane.dmg` (approximately 2.8 MiB).
- SHA-256: `b4a824f98fcaef6c4cea307bc6c699f457efd86cd45e892211cf3fad9fc42ef1`.
- Checkout base: `92b1c2ee2821797b1dd556f4291d61f596f401fc` **with uncommitted app and packaging changes**. This is a local working-tree candidate, not a reproducible committed release revision. The release helper correctly requires a clean commit before uploading.
- Test host: Apple Silicon (`arm64`), macOS 26.6.2, build 25G83.

## Automated and local evidence

| Check | Result |
| --- | --- |
| Existing native behavior suite | Passed: 47 tests across 13 suites; optional native-interface test skipped by the existing suite |
| Release failure boundaries | Passed: 7 tests cover version/revision validation, dirty checkout, existing draft/tag, API failures, failed tests/build/package verification, and draft-only creation |
| Workflow and source validation | Passed: actionlint 1.7.12, YAML parsing, shell syntax, strict OpenSpec validation, and whitespace checks |
| Universal app | Passed: arm64 and x86_64 slices; this does not demonstrate Intel runtime behavior |
| Final image | Passed: compressed read-only UDZO; checksum valid |
| Bundle identity, icon, minimum OS and version | Passed: expected identity/icon, macOS 14.0, version 2.0.0 |
| Signing | Passed: strict codesign verification and ad-hoc signature inside mounted DMG |
| Contents and destination | Passed: app, help, presentation resources, /Applications symlink; no runtime or source tree packaged |
| Saved Finder settings | Passed: 660 × 440 window, 88-point icons, expected positions, hidden toolbars/sidebar, background alias inside volume |
| Artwork | Generated background inspected; 1320 × 880 pixels at 144 DPI (660 × 440 points) |
| Paths containing spaces | Passed: build, verification and copying use paths containing spaces |
| Failure handling | Passed: wrong expected version, existing output, and truncated image rejected; no packaging/verification mounts remain attached |
| Launch after eject | Passed: app copied from image to `.build/dmg installed/Passport Filigrane.app`, image ejected, existing LaunchCheck reports a visible window; `.build/dmg-launch/bundle-launch.json` |

Implementation checks are not a substitute for the browser-downloaded acceptance below. Development logs are in `/tmp/passport-dmg-tests.log`, `/tmp/passport-dmg-build.log`, and `/tmp/passport-dmg-verify.log` for this session; they are ephemeral, so preserve release-specific evidence when preparing the committed candidate.

## Required remaining evidence

- [ ] Final Finder window visually inspected with actual icons and labels; screenshot recorded. Screen capture was unavailable in this agent session; saved metadata and background inspection do not establish final Finder appearance.
- [ ] Successful draft prepared by the committed release workflow. No workflow was pushed or dispatched; it must first be committed and available on the default branch for manual dispatch. Public-repository eligibility is now satisfied.
- [x] Public download destination resolved. On explicit maintainer instruction, `Louni-M/Privacy-Watermark` was made public on 2026-09-08. GitHub reports PUBLIC and an unauthenticated repository request returns HTTP 200.
- [ ] Browser-downloaded candidate on a fresh Apple Silicon environment, normal quarantine intact: exact prompts, per-app approval, installation, ejection, export, independent output reopen, source preservation.
- [ ] Equivalent browser-download and runtime evidence on Intel, with macOS 14 coverage across the two environments.
- [ ] Maintainer publishes the accepted draft, activates the README link, and verifies anonymous download and matching candidate hash.

Record version, full source commit, artifact hash, hardware, OS, screenshots, prompts, and outcomes for the committed candidate here. Do not reuse this local candidate's passing checks as evidence for a different binary.
