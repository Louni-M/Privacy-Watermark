#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
dmg="${1:?Usage: verify-dmg.sh path/to/Passport-Filigrane.dmg [version]}"
expected="${2:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' scripts/Info.plist)}"
hdiutil verify "$dmg" || exit 1
work="$(mktemp -d "${TMPDIR:-/tmp}/passport-verify.XXXXXX")"
mount="$work/mount"
attached=false
mkdir "$mount"
cleanup() {
    if $attached; then
        hdiutil detach "$mount" -quiet || hdiutil detach "$mount" -force -quiet || {
            echo "Could not eject $mount; leaving temporary directory in place." >&2
            return 1
        }
    fi
    rm -rf "$work"
}
trap 'verify_status=$?; cleanup; exit "$verify_status"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
hdiutil attach "$dmg" -readonly -nobrowse -mountpoint "$mount" -quiet
attached=true
hdiutil imageinfo "$dmg" -plist > "$work/image.plist"
[[ "$(plutil -extract Format raw "$work/image.plist")" == UDZO ]] || { echo 'Expected a compressed read-only UDZO image.' >&2; exit 1; }
app="$mount/Passport Filigrane.app"
plist="$app/Contents/Info.plist"
[[ "$(readlink "$mount/Applications")" == /Applications ]] || { echo 'Invalid Applications shortcut.' >&2; exit 1; }
[[ -s "$mount/Install.txt" && -s "$mount/.DS_Store" && -s "$mount/.background.png" ]] || { echo 'Missing installation resources.' >&2; exit 1; }
"${DMG_PYTHON:-$PWD/.build/dmg-tools/bin/python}" scripts/verify-dmg-layout.py "$mount" || exit 1
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" == "$expected" ]] || { echo "App version does not match $expected." >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$plist")" == 14.0 ]] || { echo 'Unexpected minimum macOS version.' >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")" == com.lounim.passportfiligrane ]] || { echo 'Unexpected bundle identity.' >&2; exit 1; }
[[ -s "$app/Contents/Resources/app_icon.icns" ]] || { echo 'Missing app icon.' >&2; exit 1; }
lipo "$app/Contents/MacOS/PassportFiligrane" -verify_arch arm64 x86_64 || exit 1
codesign --verify --strict "$app" || exit 1
codesign -dv "$app" 2>&1 | grep '^Signature=adhoc$' >/dev/null || { echo 'Expected an ad-hoc signature.' >&2; exit 1; }
for entry in "$mount"/* "$mount"/.[!.]*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    case "$(basename "$entry")" in
        'Passport Filigrane.app'|Applications|Install.txt|.background.png|.VolumeIcon.icns|.DS_Store|.fseventsd|.Trashes|.Spotlight-V100) ;;
        *) echo "Unexpected disk image content: $entry" >&2; exit 1 ;;
    esac
done
printf 'Verified universal DMG, version %s\n' "$expected"
