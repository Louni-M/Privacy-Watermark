#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"
output="${OUTPUT_DIR:-dist}"
app="$output/Privacy Watermark.app"
architectures=(arm64 x86_64)
slices=()
for architecture in "${architectures[@]}"; do
    # A scratch path per architecture keeps each slice in its own products
    # folder with both the native and the swiftbuild build systems.
    scratch=".build/arch-$architecture"
    swift build -c "$configuration" --arch "$architecture" --scratch-path "$scratch"
    slices+=("$(swift build -c "$configuration" --arch "$architecture" --scratch-path "$scratch" --show-bin-path)/PrivacyWatermark")
done
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
lipo -create "${slices[@]}" -output "$app/Contents/MacOS/PrivacyWatermark"
cp assets/app_icon.icns "$app/Contents/Resources/app_icon.icns"
cp scripts/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
for architecture in "${architectures[@]}"; do
    lipo "$app/Contents/MacOS/PrivacyWatermark" -verify_arch "$architecture"
done
printf 'Built %s\n' "$app"
