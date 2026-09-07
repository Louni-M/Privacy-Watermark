#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"
output="${OUTPUT_DIR:-dist}"
app="$output/Passport Filigrane.app"
swift build -c "$configuration" --arch arm64
swift build -c "$configuration" --arch x86_64
arm_dir="$(swift build -c "$configuration" --arch arm64 --show-bin-path)"
intel_dir="$(swift build -c "$configuration" --arch x86_64 --show-bin-path)"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
lipo -create "$arm_dir/PassportFiligrane" "$intel_dir/PassportFiligrane" -output "$app/Contents/MacOS/PassportFiligrane"
cp assets/app_icon.icns "$app/Contents/Resources/app_icon.icns"
cp scripts/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
lipo "$app/Contents/MacOS/PassportFiligrane" -verify_arch arm64 x86_64
printf 'Built %s\n' "$app"
