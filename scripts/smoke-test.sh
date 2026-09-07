#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"
smoke_output="${PASSPORT_SMOKE_OUTPUT:-.build/smoke-output}"
swift build -c "$configuration"
binary_dir="$(swift build -c "$configuration" --show-bin-path)"
architecture="$(uname -m)"
swiftc -O -parse-as-library -swift-version 6 -target "$architecture-apple-macosx14.0" \
    -I "$binary_dir/Modules" \
    Sources/PassportFiligrane/Session.swift Sources/PassportFiligrane/ContentView.swift \
    scripts/SmokeTest.swift "$binary_dir/WatermarkCore.build/"*.o \
    -o "$binary_dir/NativeSmoke"
mkdir -p "$smoke_output"
rm -f "$smoke_output/smoke.json"
"$binary_dir/NativeSmoke" "$PWD/tests/WatermarkCoreTests/Fixtures" "$smoke_output"
test -s "$smoke_output/smoke.json"
/usr/bin/plutil -extract passed raw -o - "$smoke_output/smoke.json" | /usr/bin/grep -qx true
cat "$smoke_output/smoke.json"
