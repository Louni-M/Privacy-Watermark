# Watermark workflow clarity acceptance

Date: 2026-09-11. Change: `improve-watermark-workflow-clarity`.

Implementation is complete, including the date-checkbox revision below. The operator confirmed direct file dragging works on 2026-09-11. The original implementation evidence is retained below as history; helper-specific observations are superseded by the revision.

## Build and automated checks

- Base revision: `11fd4a294b1b53b362982ac0d443bcea7b275245`, with the uncommitted change described by the OpenSpec proposal and tasks.
- Built bundle: `dist/Passport Filigrane.app`, version 2.0.2, universal arm64/x86_64; ad-hoc signature and both architecture slices verified by `scripts/build-app.sh`.
- Executable SHA-256: `b8c10ef26bff582e70c66fcc3c92edca44a09d8eb7e6bd6326a6216cdd6365b2`.
- Local execution: Apple Silicon, macOS 26.6.2 (25G83). Intel compilation passed; Intel/macOS 14 execution was not rerun locally. Existing compatibility requirements remain in effect.
- `scripts/test.sh`: 54 tests in 15 suites passed. Opt-in performance, corpus-recording and visual tests remain opt-in; none is represented as run by this command.
- Focused tests cover newline normalization, Unicode character boundaries, optional helper fields/date, exact 200-character insertion, invalid numeric drafts, reset scope, first-invalid import, eligible counts and every effective output policy.
- Rendering tests cover both directions, preserved blank lines, resolution-independent geometry, region-preview/reopened-output agreement for single-line and multiline watermarks, all export routes and PDF modes, and exact legacy single-line bitmap equality. A 200-character mark with 199 blank lines completes the sample-render responsiveness check.
- `PASSPORT_TEST_OUTPUT="$PWD/.build/workflow-review/layouts" scripts/test.sh --filter renderNativeInterface`: passed, creating 16 native captures across sample/batch, collapsed/expanded Appearance, light/dark, and 860×600/1040×720 content sizes. The test asserts exact content dimensions. Representative minimum-size light/dark captures were visually inspected; settings remain readable and the scroll area holds controls below the fold.
- `PASSPORT_SMOKE_OUTPUT="$PWD/.build/workflow-review/smoke-final" scripts/smoke-test.sh`: passed, including built-bundle launch, native panels, mixed batch processing, PDF reopen, page folders, write failures, cooperative cancellation and recovery.
- Offline check: ran the compiled `NativeSmoke.app/Contents/MacOS/NativeSmoke` under `sandbox-exec -p '(version 1)(allow default)(deny network*)'`, with synthetic fixtures and `.build/workflow-review/offline-final` as output. Passed. The first attempt wrapped SwiftPM itself and failed because macOS disallows its nested sandbox; compiling normally before sandboxing only the test process resolved that test-environment issue.
- `shellcheck scripts/smoke-test.sh`, `git diff --check`, and `openspec validate improve-watermark-workflow-clarity --strict`: passed. `graft build` refreshed the ignored local context graph.

Raw logs, rendered captures, disposable harnesses and exported files stay under ignored `.build/workflow-review/`. No personal documents were used. No installed application, release, remote repository or live service was updated.

## Direct native UI observations

Opened the built bundle through Finder and used computer control to exercise:

- Prominent Add files action, labeled fictional sample, and hidden empty file column. Editing appearance/text updates the sample; it never enables export.
- Helper recipient and purpose, removable date, exact generated multiline text, and Use this text. Keyboard submission and the helper shortcut work; inserted text remains freely editable.
- Appearance expansion, numeric entry with Return/focus-loss commit, slider synchronization, and Reset appearance retaining the text. A stronger test exposed that the initial formatter accepted `42junk`; the fixed implementation restores the previous value, confirmed in a native field as well as tests.
- Zero opacity without any warning or confirmation. Existing tests also verify empty text remains exportable with eligible files.
- Native Add files cancellation and mixed fixture import: one JPG, one long-named PNG, one two-page PDF and one corrupt PDF. The sample gives way to the real file list and preview; the invalid row stays visible.
- Original-format prediction: 3 documents, 1 PDF, 1 JPG and 1 PNG, with one excluded invalid document. PNG prediction: 3 documents, 4 PNG images, including two PDF page images in one folder and two standalone copies.
- Export via Shift-Command-S, destination cancellation, then export into the isolated output folder. Actual feedback was 3 saved, 1 failed (the already-invalid candidate), 0 not processed, preserving the existing result semantics.
- Reveal in Finder and reopening a saved synthetic PNG with Quick Look. The saved multiline watermark matched its preview. Filesystem checks confirmed all four input fixture copies were byte-for-byte unchanged, and the four PNG outputs comprised two standalone files plus ordered `_page_001`/`_page_002` images in the PDF folder. Finder's `.DS_Store` is excluded from document-output counts.
- Direct divider resizing from 260 to 372 points, long filename display, expanded-control scrolling, and Clear all returning to the sample while preserving shared settings.
- Keyboard workflow: Command-O import, Shift-Command-H helper, Tab between helper fields, Return to insert, Shift-Command-A Appearance, Control-Tab to leave the multiline editor, Tab between numeric fields, Return to commit, Shift-Command-R reset, and Shift-Command-S export. Accessible names are exposed for the new text editor, helper, numeric fields, sample and export action.

## Original direct drag check

Computer control did not complete a file drag from Finder into the app despite selecting the fixture, activating windows, arranging them side by side and retrying. It also failed to complete a same-window drag from a temporary `.draggable(URL)` source into the exact product ContentView. These attempts do not establish whether physical Finder drag-and-drop passes or fails.

The existing native URL drop handler remains in place, now with hover feedback for the outlined empty-state target. The operator was asked to drag `example-photo.jpg` from the prepared Finder input folder into the open Passport Filigrane build and confirm that the file list and preview appear. The operator subsequently confirmed “it works” on 2026-09-11, closing the drag acceptance task.

## Date-checkbox revision — 2026-09-11

- Removed helper button, sheet, draft model, composition API, and Shift-Command-H shortcut. Added Include today’s date with Shift-Command-D. The checkbox edits shared watermark text directly, so the existing preview/export settings path remains shared.
- Fixed Gregorian `yyyy-MM-dd` date formatting uses the local time zone and two-digit month/day. Tests verify September 9, a time-zone day boundary, empty text, exact-line deduplication, repeated toggles, manual edits, removal from the middle of text, and a complete date at the 200-character Unicode boundary.
- `scripts/test.sh`: 55 tests in 15 suites passed after the final shortcut change. `scripts/build-app.sh`: universal release build passed. Final executable SHA-256: `40d8871108b827219835ca82710405211c0dea8ebade57b9404c7d97309bc151`.
- `PASSPORT_TEST_OUTPUT="$PWD/.build/workflow-review/date-layouts" scripts/test.sh --filter renderNativeInterface`: passed, 16 captures. Inspected expanded minimum-size batch layouts in light and dark appearance; checkbox and text are readable. The later shortcut-only change does not alter layout.
- `PASSPORT_SMOKE_OUTPUT="$PWD/.build/workflow-review/date-smoke" scripts/smoke-test.sh`: passed after checkbox implementation; the subsequent shortcut-only change was built and tested directly. Smoke output’s generic “manual drag pending” message is superseded by the operator confirmation above.
- Direct computer-use verification ran a separate copy of the final universal build with a review bundle identifier; the operator’s existing open app session was retained. Observed initial unchecked state; click and Shift-Command-D insert/remove `Date: 2026-09-11`; count and sample watermark update; repeated toggles do not duplicate the date; Reset appearance retains date/text; manual date editing clears the checkbox; Shift-Command-H opens no helper. The checkbox is inside the existing export-disabled control group, and existing session mutation-lock tests pass.
- README documents the checkbox, shortcut, padded date, and length-limit behavior. Generated review bundles, screenshots and logs remain ignored under `.build/workflow-review/`.

## Prefix-free date and black slider refinement — 2026-09-11

This revision supersedes the previous date format. The checkbox now inserts only `DD-MM-YYYY`, for example `11-09-2026`, with no prefix. Date tests cover distinct day/month ordering, zero padding, local time-zone boundaries, toggling/editing, and the updated 189-character text budget when inserting a ten-character date plus newline. Reopened-output parity tests now also run with `COPY\n11-09-2026` through the supported export routes.

The three appearance sliders use native NSSlider tracking, accessibility, keyboard behavior and thumb drawing, with a custom bar that retains blue fill and makes the unfilled portion black. Clicking gives the slider keyboard focus. Direct computer-use checks verified opacity changes from 50 to 55 using Right, text-size pointer/keyboard adjustment to 45, and spacing adjustment to 162.5 using Left; numeric fields and sample preview stayed synchronized. Native screenshots confirm black tracks, blue fill and light thumbs in both light and dark minimum-size layouts. Focus is visible on the active slider. The inherited export lock is forwarded through the representable’s isEnabled environment.

Verified the date shortcut inserts `11-09-2026` into the editor, shows 15 characters for COPY plus newline plus date, and renders that date in the sample. User’s original open document session remained untouched; interaction used an isolated review bundle. The last source change after direct verification was only a MainActor annotation on the slider callback, resolving the smoke compiler warning.

- Final standard tests: 55 tests in 15 suites passed, including three reopened-route text cases.
- Universal release build passed. Final executable SHA-256: `36bde8f96719fa74f640d6812bf6145b807c8d8f013f1693886d0593c2caff2b`.
- Layout test produced 16 captures under `.build/workflow-review/refine-layouts`; light/dark minimum-size expanded batch captures were inspected.
- Final logs: `.build/workflow-review/refine-tests-final.log`, `refine-build-final.log`, and `refine-smoke.log`.
- README and OpenSpec describe the final date and slider behavior; generated evidence stays ignored.

Final native smoke checks passed without compiler warnings. Strict OpenSpec validation and git diff whitespace checks passed; the local graft graph was refreshed.
