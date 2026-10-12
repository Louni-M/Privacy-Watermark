# Spec Delta

## ADDED Requirements

### Requirement: Bundled command-line tool
The universal `Privacy Watermark.app` SHALL contain a `pwm` executable with both `arm64` and `x86_64` slices, built from the same source revision and covered by the bundle's ad-hoc signature. The tool and the Quick Action SHALL require no additional runtime, package manager or third-party dependency. Build verification SHALL fail if `pwm` is missing, lacks an architecture, fails strict signature verification, or reports a version different from the app's `CFBundleShortVersionString`. Launching the app normally SHALL be unaffected.

#### Scenario: Verify a built app
- **WHEN** the maintainer builds the app with the standard build script
- **THEN** verification confirms `pwm` is present, universal, signed and reports the app version

#### Scenario: Missing slice
- **WHEN** `pwm` is built for only one architecture
- **THEN** the build script fails and does not report a successful app

### Requirement: Command-line and Quick Action documentation
The README SHALL document `pwm` usage, defaults, exit status, presets, `--strip-only`, and the install and uninstall commands for the Finder Quick Action. The documentation SHALL also state that the Quick Action writes copies beside the originals, and SHALL give the location of the preset file and say that it can contain private watermark text. Security documentation SHALL state that the command and the Quick Action process documents locally and keep no log of contents or watermark text.

#### Scenario: Find CLI instructions
- **WHEN** a user reads the README after installing the app
- **THEN** they can find how to install the Watermark Quick Action and run `pwm --help` without reading source code
