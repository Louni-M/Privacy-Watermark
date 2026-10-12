#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
smoke_output="${PASSPORT_SMOKE_OUTPUT:-.build/smoke-output}"
if [[ -d 'dist/Privacy Watermark.app' ]]; then
    swift scripts/LaunchCheck.swift "$PWD/dist/Privacy Watermark.app" "$smoke_output"
fi
architecture="$(uname -m)"
target="$architecture-apple-macosx14.0"
smoke_dir=".build/smoke"
smoke_app="$smoke_dir/NativeSmoke.app"
# Compile WatermarkCore directly so the smoke app does not depend on the
# build system's intermediate layout, which differs between SwiftPM versions.
rm -rf "$smoke_dir"
mkdir -p "$smoke_dir/Modules" "$smoke_app/Contents/MacOS"
swiftc -O -parse-as-library -swift-version 6 -target "$target" \
    -module-name WatermarkCore -emit-library -static \
    -emit-module -emit-module-path "$smoke_dir/Modules/WatermarkCore.swiftmodule" \
    Sources/WatermarkCore/*.swift \
    -o "$smoke_dir/libWatermarkCore.a"
swiftc -O -parse-as-library -swift-version 6 -target "$target" \
    -I "$smoke_dir/Modules" \
    Sources/PrivacyWatermark/Session.swift Sources/PrivacyWatermark/ContentView.swift \
    Sources/PrivacyWatermark/PreviewWorker.swift Sources/PrivacyWatermark/PreviewHost.swift \
    Sources/PrivacyWatermark/WorkflowControls.swift \
    scripts/SmokeTest.swift "$smoke_dir/libWatermarkCore.a" \
    -o "$smoke_app/Contents/MacOS/NativeSmoke"
cp scripts/Info.plist "$smoke_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.lounim.privacywatermark.smoke' "$smoke_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable NativeSmoke' "$smoke_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName NativeSmoke' "$smoke_app/Contents/Info.plist"
codesign --force --sign - "$smoke_app"
mkdir -p "$smoke_output"
rm -f "$smoke_output/smoke.json"
"$smoke_app/Contents/MacOS/NativeSmoke" "$PWD/tests/WatermarkCoreTests/Fixtures" "$smoke_output"
test -s "$smoke_output/smoke.json"
/usr/bin/plutil -extract passed raw -o - "$smoke_output/smoke.json" | /usr/bin/grep -qx true
cat "$smoke_output/smoke.json"
