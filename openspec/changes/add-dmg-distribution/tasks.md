## 1. Confirm release prerequisites

- [x] 1.1 Inspect existing GitHub releases, repository visibility, and available no-cost runner capacity; record the selected runner and local fallback without changing visibility or enabling paid usage.
- [x] 1.2 Define release version/revision validation and stable DMG naming using the existing Info.plist version as the source of truth.

## 2. Build the installation disk image

- [x] 2.1 Add isolated, repeatable DMG packaging around the existing universal app build, with an Applications symlink, installation document, compressed read-only output, and temporary mount cleanup on failure.
- [ ] 2.2 Add the deliberate Finder layout and presentation assets using the existing app icon; verify app, destination, arrow, and instructions are visible together without clipping.
- [x] 2.3 Add package verification for image integrity, staged contents, shortcut target, bundled version/minimum OS, both architectures, and the enclosed ad-hoc signature; exercise failure cleanup and a path containing spaces.

## 3. Prepare draft releases

- [x] 3.1 Add manual release dispatch with validated version and source revision, serialized execution, scoped repository-token permissions, and rejection of existing tags/releases.
- [x] 3.2 Run existing native tests and package checks before preparing the draft and attaching the DMG with source revision and installation notes; report incomplete uploads as failures and never auto-publish.
- [ ] 3.3 Verify version mismatch, duplicate release, and failed verification paths cannot overwrite or publish a release; prepare one successful draft candidate through the workflow when repository access permits.

## 4. Explain download and installation

- [x] 4.1 Add prominent README download access, macOS/processor requirements, and installation steps, with an explicit unavailable state until a public DMG exists; retain separate developer build instructions.
- [x] 4.2 Provide matching release and offline DMG instructions for copying, ejecting, opening, and per-app Privacy & Security approval; verify current Apple guidance and include concise help for unavailable approval or different errors.
- [x] 4.3 Document local packaging/manual draft upload, maintainer publication steps, anonymous-link verification, and recovery from a defective public download.

## 5. Record release acceptance

- [x] 5.1 Create a candidate-specific acceptance record separating automated package evidence from browser-download installation evidence, with explicit pending states and version/revision/system details.
- [ ] 5.2 Run native tests and final DMG verification; visually inspect the mounted final image and confirm the installed app runs after ejecting it.
- [ ] 5.3 Verify the browser-downloaded candidate under normal quarantine on Apple Silicon and Intel, covering macOS 14; record exact security prompts, documented recovery, and successful synthetic watermark export with unchanged source and independently reopened output. Leave unavailable environments pending.
- [ ] 5.4 Hand off the accepted draft for the maintainer's manual publication. Record the publication/link activation checklist; once the maintainer publishes, verify anonymous README download access to the intended DMG. Keep publication and its dependent checks explicitly pending until performed.

Implementation evidence and remaining release prerequisites are recorded in `docs/releases/acceptance.md`. Tasks 2.2 and 5.2 retain pending visual Finder inspection; 3.3 retains pending real workflow execution; 5.3 and 5.4 retain downloaded-install and publication gates. The maintainer authorized making the existing source repository public; this is now complete and anonymous access is verified. Workflow execution still requires the release tooling and its source revision to be committed and pushed.
