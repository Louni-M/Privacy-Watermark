#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${OUTPUT_DIR:-dist}"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
dmg="$output/Passport-Filigrane.dmg"
[[ ! -e "$dmg" ]] || { echo "Refusing to overwrite $dmg; choose an empty OUTPUT_DIR." >&2; exit 1; }
work="$(mktemp -d "${TMPDIR:-/tmp}/passport-dmg.XXXXXX")"
trap 'build_status=$?; rm -rf "$work"; exit "$build_status"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$work/stage"
packager="${DMGBUILD:-$PWD/.build/dmg-tools/bin/dmgbuild}"
[[ -x "$packager" ]] || {
    echo 'Install packaging tools: python3 -m venv .build/dmg-tools && .build/dmg-tools/bin/pip install -r scripts/dmg-requirements.txt' >&2
    exit 1
}
CONFIGURATION=release OUTPUT_DIR="$work/stage" scripts/build-app.sh
cp assets/dmg/Install.txt "$work/stage/Install.txt"
swift scripts/dmg-background.swift "$work/stage/background.png"
"$packager" -s scripts/dmg-settings.py -D "stage=$work/stage" \
    'Passport Filigrane' "$work/Passport-Filigrane.dmg"
scripts/verify-dmg.sh "$work/Passport-Filigrane.dmg"
mv "$work/Passport-Filigrane.dmg" "$dmg"
shasum -a 256 "$dmg"
printf 'Built %s\n' "$dmg"
