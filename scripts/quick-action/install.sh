#!/bin/bash
# Installs the Finder "Watermark" Quick Action for the current user only.
#
#   install.sh [--link [DIR]] [--pwm PATH]
#
#   --link [DIR]  Also link pwm into DIR (default ~/.local/bin) to type `pwm`.
#   --pwm PATH    Use this pwm instead of the one beside this script.
#
# Needs no administrator rights and never changes Gatekeeper or quarantine.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
identifier=com.lounim.privacywatermark.quickaction
services="$HOME/Library/Services"
workflow="$services/Watermark.workflow"

link_dir="" pwm=""
while (($#)); do
    case "$1" in
        --link)
            link_dir="$HOME/.local/bin"
            if (($# > 1)) && [[ "$2" != --* ]]; then link_dir="$2"; shift; fi ;;
        --pwm)
            (($# > 1)) || { echo "install.sh: --pwm needs a path." >&2; exit 64; }
            pwm="$2"; shift ;;
        -h|--help) sed -n '2,9s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *) echo "install.sh: unknown option $1" >&2; exit 64 ;;
    esac
    shift
done

# Inside the app this script is Contents/Resources/quick-action/install.sh.
# From a checkout, use the app built by scripts/build-app.sh, then the installed app.
if [[ -z "$pwm" ]]; then
    for candidate in "$here/../../MacOS/pwm" "$here/../../dist/Privacy Watermark.app/Contents/MacOS/pwm" \
                     "/Applications/Privacy Watermark.app/Contents/MacOS/pwm" "$HOME/Applications/Privacy Watermark.app/Contents/MacOS/pwm"; do
        if [[ -f "$candidate" && -x "$candidate" ]]; then pwm="$candidate"; break; fi
    done
fi
if [[ -z "$pwm" || ! -f "$pwm" || ! -x "$pwm" ]]; then
    echo "install.sh: pwm was not found. Install Privacy Watermark in Applications, or run scripts/build-app.sh first." >&2
    exit 1
fi
pwm="$(cd "$(dirname "$pwm")" && pwd)/$(basename "$pwm")"
if ! "$pwm" --version >/dev/null 2>&1; then
    echo "install.sh: $pwm did not run. Open Privacy Watermark once and approve it in System Settings → Privacy & Security, then run this again." >&2
    exit 1
fi

if [[ -e "$workflow" || -L "$workflow" ]]; then
    existing="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$workflow/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$existing" != "$identifier" ]]; then
        echo "install.sh: $workflow exists and was not installed by Privacy Watermark. Rename or remove it, then run this again." >&2
        exit 1
    fi
fi

# Build the new bundle beside the old one, then swap, so a failure keeps the old one.
mkdir -p "$services"
staged="$(mktemp -d "$services/.Watermark.workflow.XXXXXX")"
trap 'rm -rf "$staged"' EXIT
cp -R "$here/Watermark.workflow/Contents" "$staged/Contents"
mkdir -p "$staged/Contents/Resources"
cp "$here/watermark.zsh" "$staged/Contents/Resources/watermark.zsh"
chmod 755 "$staged/Contents/Resources/watermark.zsh"
printf '%s\n' "$pwm" > "$staged/Contents/Resources/pwm-path"

# Keep track of a link made by an earlier installation, so uninstall still removes it.
previous_link=""
if [[ -r "$workflow/Contents/Resources/pwm-link" ]]; then previous_link="$(cat "$workflow/Contents/Resources/pwm-link")"; fi

if [[ -n "$link_dir" ]]; then
    mkdir -p "$link_dir"
    link_dir="$(cd "$link_dir" && pwd)"
    link="$link_dir/pwm"
    if [[ -e "$link" && ! -L "$link" ]]; then
        echo "install.sh: $link exists and is not a link. Remove it or choose another folder with --link DIR." >&2
        exit 1
    fi
    ln -sfn "$pwm" "$link"
    printf '%s\n' "$link" > "$staged/Contents/Resources/pwm-link"
elif [[ -n "$previous_link" && -L "$previous_link" ]]; then
    ln -sfn "$pwm" "$previous_link"
    printf '%s\n' "$previous_link" > "$staged/Contents/Resources/pwm-link"
fi

rm -rf "$workflow"
mv "$staged" "$workflow"
trap - EXIT
/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true

echo "Installed the Watermark Quick Action in $workflow"
echo "It uses $pwm"
echo "In Finder, Control-click JPG, PNG or PDF files and choose Quick Actions → Watermark."
if [[ -n "$link_dir" ]]; then
    echo "Linked $link_dir/pwm"
    case ":$PATH:" in
        *":$link_dir:"*) ;;
        *) echo "$link_dir is not on your PATH. To add it, run:"
           printf "  echo 'export PATH=\"%s:\$PATH\"' >> ~/.zprofile\n" "$link_dir"
           echo "then open a new Terminal window." ;;
    esac
fi
