#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/app_icon.iconset"
for points in 16 32 128 256 512; do
    for scale in 1 2; do
        pixels=$((points * scale))
        suffix=""
        [[ "$scale" == 1 ]] || suffix="@2x"
        sips -z "$pixels" "$pixels" master.png --out "$work/app_icon.iconset/icon_${points}x${points}${suffix}.png" >/dev/null
    done
done
iconutil -c icns "$work/app_icon.iconset" -o ../app_icon.icns
