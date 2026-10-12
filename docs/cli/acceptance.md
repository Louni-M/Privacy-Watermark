# pwm CLI and Finder Quick Action evidence

Status: complete on this Mac. The user accepted the Finder Quick Action after using it. macOS 14 and Intel manual coverage is pending.

## Environment

Recorded 2026-10-12 on Apple Silicon (`arm64`), macOS 27.0.1 (26A434). Base revision: d3ce3f3696a378f1790b5ffb82d17f49bde61dbf, with the change's uncommitted implementation. The app was built with `scripts/build-app.sh`, and the Quick Action was installed with `scripts/quick-action/install.sh`. It records `<workspace>/dist/Privacy Watermark.app/Contents/MacOS/pwm` as the `pwm` path.

## Manual Finder acceptance

The user installed the Quick Action, ran **Quick Actions → Watermark** from Finder on their own files and reported that it works. They had to turn the Quick Action on by hand before it appeared in the menu; macOS installed it turned off. The README now says that it may be installed turned off and lists the three places to turn it on.

This is user sign-off, not an agent-observed or itemized manual test report. The user's files, text and output paths were not recorded. Cancel, partial failure with Reveal in Finder, presets and uninstall were not reported item by item. They are covered by the automated tests below, which stub `osascript` and `pwm` and do not drive Finder.

## Automated coverage

| Behavior | Evidence |
|---|---|
| Copies beside the originals, ` (2)` names, PDF page-image folders, originals unchanged by hash | `PWMCommandTests` runner fixtures |
| Same output as the app, accented text under `LC_ALL=C` | `PWMCommandTests` end-to-end test on the built `pwm` |
| Exit codes, stdout/stderr split, watermark text never in stderr | `PWMCommandTests` reporting tests |
| Control-C keeps completed copies and leaves no staging | `PWMCommandTests` cancellation test |
| Control-C on the built `pwm`, agent-observed (task 4.3): SIGINT on 2026-10-12 (`arm64`, same macOS) while exporting three multi-page synthetic PDFs gave exit 130 and `pwm: interrupted.` then `1 saved · 0 failed · 0 excluded · 2 not processed` on stderr; the first copy was kept and no staging folder was left | Manual run of `<workspace>/dist/Privacy Watermark.app/Contents/MacOS/pwm` on synthetic files |
| `pwm --version` prints the app version (`pwm 2.1.3`) through a link such as the one `install.sh --link` creates, run by path and from `PATH` (fixed: it printed `pwm dev`); `swift run pwm --version` still prints `pwm dev` | `scripts/verify-app.sh`, run by `scripts/build-app.sh` |
| Accented text with and without date, cancel, missing `pwm`, moved app, partial failure with Reveal in Finder, nothing saved, over-limit text, presets | `python3 scripts/test-quick-action.py` (15 tests, passed) |
| Install, `--link`, reinstall and uninstall touch only their own files, no administrator rights or quarantine changes | `python3 scripts/test-quick-action.py` |
| Build, tests and app smoke test unchanged | `swift build`, `scripts/test.sh`, `scripts/build-app.sh`, `scripts/smoke-test.sh` (task 7.1) |

## Mixed selection

The user reported on 2026-10-12 that Finder does not offer **Watermark** when the selection includes a `.txt` file. The service accepts only JPEG, PNG and PDF, so unsupported files never reach `pwm`. The `finder-quick-action` spec now states this behavior.

## Pending

Manual Finder checks not yet performed, item by item:

- Cancel: dismiss a dialog and confirm nothing is written.
- Partial failure: confirm the failure alert offers Reveal in Finder and that it reveals the right file.
- Preset: choose a preset in the picker and confirm the copies use it.
- Uninstall: run `scripts/quick-action/uninstall.sh` and confirm Watermark leaves the Quick Actions menu.
- Manual Finder run on macOS 14.
- Manual Finder run on an Intel Mac.
