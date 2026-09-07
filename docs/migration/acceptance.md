# Native migration acceptance record

Status: implementation in progress; acceptance and legacy cleanup are not complete.

## Reference

Legacy revision: `752369ed5b6abc8c395a23ab1a240d77cd3508fc`.
Local host: Apple Silicon, macOS 26.6.2 (25G83); Swift 6.3.3 Command Line Tools.

`legacy-tests.txt`: 119 passed, 1 skipped (legacy fixture-only test), 5 dependency deprecation warnings.
`legacy-environment.txt`: exact installed Python reference dependencies.
`legacy-processing.json`: 10 measurements per route, explicit standard/300/450/600-DPI modes, fixture SHA-256 hashes, process peak RSS. Core processing timings do not prove GUI preview or launch latency.

Synthetic fixtures are in `Tests/WatermarkCoreTests/Fixtures`. Temporary comparison exports and the packaged Python app are under ignored `.migration/` pending acceptance.

Known legacy defects excluded from parity: standard export mutates the loaded PDF, repeated exports can accumulate watermarks, image export can use stale-format preview bytes. The old raster renderer applies stamp opacity twice; native visual comparison must account for this rather than silently changing apparent opacity.

## Environment prerequisites

Both architectures can be compiled locally; x86_64 can execute under Rosetta. Rosetta is not proof of native execution on Intel hardware. The connected GitHub repository has no registered self-hosted runners. Minimum macOS 14 and native Intel runtime evidence remain pending; the local macOS 26 ARM host cannot provide those checks alone.

Local screen capture permission is currently unavailable. Own-app render capture and native model/integration tests will be used where possible; external viewer and dialog interaction evidence must be recorded honestly.

## Pending acceptance

- Complete format/parameter/privacy/failure parity and visual comparison.
- Saved/reopened PDF geometry, annotations, links, source/watermark text, and flattened image resolutions.
- Packaged launch and end-to-end preview timing, same-mode export comparisons, stress and peak memory.
- Runtime checks on both architectures and minimum macOS.
- Cleanup only after acceptance, followed by native-only build/test and bundle audit.
