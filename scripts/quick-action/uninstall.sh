#!/bin/bash
# Removes the Finder "Watermark" Quick Action and the pwm link install.sh made.
# The app, presets and documents are left untouched.
set -euo pipefail
identifier=com.lounim.privacywatermark.quickaction
workflow="$HOME/Library/Services/Watermark.workflow"

if [[ ! -e "$workflow" && ! -L "$workflow" ]]; then
    echo "The Watermark Quick Action is not installed."
    exit 0
fi
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$workflow/Contents/Info.plist" 2>/dev/null || true)" != "$identifier" ]]; then
    echo "uninstall.sh: $workflow was not installed by Privacy Watermark; leaving it in place." >&2
    exit 1
fi

# Only a link that install.sh recorded, and only while it is still a link to a pwm.
if [[ -r "$workflow/Contents/Resources/pwm-link" ]]; then
    link="$(cat "$workflow/Contents/Resources/pwm-link")"
    if [[ -L "$link" && "$(readlink "$link")" == */pwm ]]; then
        rm -f "$link"
        echo "Removed $link"
    fi
fi

rm -rf "$workflow"
/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
echo "Removed the Watermark Quick Action."
