#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"
output="${OUTPUT_DIR:-dist}"
app="$output/Privacy Watermark.app"
architectures=(arm64 x86_64)
bin_dirs=()
for architecture in "${architectures[@]}"; do
    # A scratch path per architecture keeps each slice in its own products
    # folder with both the native and the swiftbuild build systems.
    scratch=".build/arch-$architecture"
    swift build -c "$configuration" --arch "$architecture" --scratch-path "$scratch"
    bin_dirs+=("$(swift build -c "$configuration" --arch "$architecture" --scratch-path "$scratch" --show-bin-path)")
done
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
for executable in PrivacyWatermark pwm; do
    slices=()
    for bin_dir in "${bin_dirs[@]}"; do slices+=("$bin_dir/$executable"); done
    lipo -create "${slices[@]}" -output "$app/Contents/MacOS/$executable"
done
cp assets/app_icon.icns "$app/Contents/Resources/app_icon.icns"
rm -rf "$app/Contents/Resources/quick-action"
cp -R scripts/quick-action "$app/Contents/Resources/quick-action"
cp scripts/Info.plist "$app/Contents/Info.plist"
# Nested code is signed first, so the app signature seals it.
codesign --force --sign - "$app/Contents/MacOS/pwm"
codesign --force --sign - "$app"
# Both slices of both executables, strict signatures and the pwm version.
scripts/verify-app.sh "$app"
printf 'Built %s\n' "$app"
