#!/bin/bash
# Verifies a built Privacy Watermark.app: universal app and pwm executables,
# strict signature, pwm reporting the app version, and the Quick Action files.
set -euo pipefail
app="${1:?Usage: verify-app.sh path/to/Privacy\ Watermark.app}"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
for executable in PrivacyWatermark pwm; do
    [[ -f "$app/Contents/MacOS/$executable" ]] || { echo "Missing Contents/MacOS/$executable." >&2; exit 1; }
    # One architecture per check: newer lipo accepts only one -verify_arch value.
    for arch in arm64 x86_64; do
        lipo "$app/Contents/MacOS/$executable" -verify_arch "$arch" || { echo "$executable is missing its $arch slice." >&2; exit 1; }
    done
done
codesign --verify --strict "$app/Contents/MacOS/pwm" || { echo 'pwm signature is invalid.' >&2; exit 1; }
codesign --verify --strict "$app" || { echo 'App signature is invalid.' >&2; exit 1; }
reported="$("$app/Contents/MacOS/pwm" --version)" || { echo 'pwm --version failed.' >&2; exit 1; }
[[ "$reported" == "pwm $version" ]] || { echo "pwm reports \"$reported\", expected \"pwm $version\"." >&2; exit 1; }
# A link to pwm (what install.sh --link creates) must report the app version too, run by path and from PATH.
link_folder="$(mktemp -d)"
trap 'rm -rf "$link_folder"' EXIT
ln -s "$(cd "$app" && pwd)/Contents/MacOS/pwm" "$link_folder/pwm"
for through_path in false true; do
    if $through_path; then reported="$(PATH="$link_folder:/usr/bin:/bin" pwm --version)"
    else reported="$("$link_folder/pwm" --version)"; fi || { echo "pwm --version through a link failed." >&2; exit 1; }
    [[ "$reported" == "pwm $version" ]] || { echo "Linked pwm reports \"$reported\", expected \"pwm $version\"." >&2; exit 1; }
done
for file in install.sh uninstall.sh watermark.zsh Watermark.workflow/Contents/Info.plist Watermark.workflow/Contents/document.wflow; do
    [[ -s "$app/Contents/Resources/quick-action/$file" ]] || { echo "Missing Quick Action file $file." >&2; exit 1; }
done
for file in install.sh uninstall.sh watermark.zsh; do
    [[ -x "$app/Contents/Resources/quick-action/$file" ]] || { echo "Quick Action file $file is not executable." >&2; exit 1; }
done
