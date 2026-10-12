#!/bin/zsh
# Finder "Watermark" Quick Action. Receives the selected files as arguments,
# asks for the watermark text and runs pwm, which saves copies beside them.
#
# Text, file names and messages reach AppleScript only through argv, never by
# interpolation into AppleScript source. Feedback never includes the text.
emulate -L zsh
setopt pipe_fail
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

here=${0:A:h}
(( $# )) || exit 0

# Prints the button chosen. Buttons default to OK; the last one is the default.
alert() {
    osascript - "$@" <<'APPLESCRIPT'
on run argv
    set theButtons to {"OK"}
    if (count of argv) > 2 then set theButtons to items 3 thru -1 of argv
    set answer to display alert (item 1 of argv) message (item 2 of argv) buttons theButtons default button (count of theButtons)
    return button returned of answer
end run
APPLESCRIPT
}

# Success confirmation that closes by itself, not a notification:
# from osascript it is posted as Script Editor, which shows a blank banner
# and opens Script Editor on recent macOS. Prints the button, or nothing.
confirm() {
    osascript - "$1" "$2" <<'APPLESCRIPT'
on run argv
    set answer to display alert (item 1 of argv) message (item 2 of argv) buttons {"Reveal in Finder", "OK"} default button "OK" giving up after 5
    if gave up of answer then return ""
    return button returned of answer
end run
APPLESCRIPT
}

# Selects the saved copies in Finder.
reveal() {
    osascript - "$@" <<'APPLESCRIPT' >/dev/null || open -R -- "$1"
on run argv
    set theItems to {}
    repeat with thePath in argv
        set end of theItems to (POSIX file (contents of thePath)) as alias
    end repeat
    tell application "Finder"
        reveal theItems
        activate
    end tell
end run
APPLESCRIPT
}

# The path recorded by install.sh, then the app in either Applications folder.
find_pwm() {
    local -a candidates
    local candidate folder
    [[ -r $here/pwm-path ]] && candidates+=("$(<$here/pwm-path)")
    for folder in ${(s.:.)${WATERMARK_APP_LOCATIONS:-/Applications:$HOME/Applications}}; do
        candidates+=("$folder/Privacy Watermark.app/Contents/MacOS/pwm")
    done
    for candidate in $candidates; do
        [[ -f $candidate && -x $candidate ]] && { print -r -- $candidate; return 0 }
    done
    return 1
}

if ! pwm=$(find_pwm); then
    alert "Privacy Watermark is not installed" "The Watermark Quick Action needs Privacy Watermark. Move Privacy Watermark to Applications, open it once, then reinstall the Quick Action by running Contents/Resources/quick-action/install.sh from the app. No file was processed." >/dev/null
    exit 0
fi

# Presets first, when the preset file defines any.
preset=""
if names=$("$pwm" --list-presets 2>&1); then
    if [[ -n $names ]]; then
        choice=$(osascript - "${(@f)names}" "Custom text…" <<'APPLESCRIPT'
on run argv
    set choice to choose from list argv with title "Watermark" with prompt "Choose a preset, or Custom text…" default items {item -1 of argv} OK button name "Continue"
    if choice is false then return ""
    return item 1 of choice
end run
APPLESCRIPT
        ) || exit 0
        [[ -n $choice ]] || exit 0
        [[ $choice == "Custom text…" ]] || preset=$choice
    fi
else
    answer=$(alert "Presets are unavailable" "${names#pwm: }" "Cancel" "Continue without presets") || exit 0
    [[ $answer == "Continue without presets" ]] || exit 0
fi

work=""
trap '[[ -n $work ]] && rm -rf -- "$work"' EXIT

# Runs pwm; sets code, saved (paths) and errors (lines).
run_pwm() {
    work=$(mktemp -d "${TMPDIR:-/tmp}/watermark.XXXXXX") || return 1
    "$pwm" "$@" >"$work/out" 2>"$work/err"
    code=$?
    saved=("${(@f)$(<$work/out)}"); saved=(${saved:#})
    errors=("${(@f)$(<$work/err)}"); errors=(${errors:#})
    rm -rf -- "$work"; work=""
}

# A preset with its own text runs directly. pwm reports missing text before
# reading any file, so a preset without text asks for it like Custom text.
preset_args=()
[[ -n $preset ]] && preset_args=(--preset "$preset")
if [[ -n $preset && $("$pwm" --preset "$preset" 2>&1) != *"Missing watermark text"* ]]; then
    run_pwm $preset_args -- "$@"
else
    text="" message="Watermark text for the selected files. Type \\n for a new line."
    while true; do
        reply=$(osascript - "$message" "$text" <<'APPLESCRIPT' && print -n .
on run argv
    set answer to display dialog (item 1 of argv) default answer (item 2 of argv) with title "Watermark" buttons {"Cancel", "Without date", "With date"} default button "With date" cancel button "Cancel"
    return (button returned of answer) & linefeed & (text returned of answer)
end run
APPLESCRIPT
        ) || exit 0
        reply=${reply%$'\n.'}
        button=${reply%%$'\n'*}
        text=${reply#*$'\n'}
        [[ $button == "With date" ]] && date=--date || date=--no-date
        run_pwm $preset_args --text "$text" $date -- "$@"
        # Too-long text is refused before any file is read: ask again.
        if (( code == 64 )) && [[ ${(F)errors} == *"The maximum is 200"* ]]; then
            message="${${errors[1]}#pwm: } Shorten it and try again."
            continue
        fi
        break
    done
fi

if (( code == 0 )); then
    (( ${#saved} == 1 )) && noun=copy || noun=copies
    answer=$(confirm "${#saved} $noun saved" "Each copy is beside its original.") || exit 0
    [[ $answer == "Reveal in Finder" ]] && reveal "${saved[@]}"
    exit 0
fi

# Usage or preset-file problems: nothing was processed.
if (( code != 1 && code != 2 && code != 130 )); then
    alert "Watermark could not start" "${(F)${${errors:#Run pwm --help*}#pwm: }}" >/dev/null
    exit 0
fi

# Name each affected file with its reason, then the summary.
lines=()
for line in $errors; do
    case $line in
        Excluded:\ *|Failed:\ *)
            kind=${line%%: *} rest=${line#*: }
            file=${rest% — *}
            lines+=("$kind: ${file:t} — ${rest#"$file — "}") ;;
    esac
done
lines+=("" "${errors[-1]}")
title="Some files were not watermarked"
(( code == 2 )) && title="No file was watermarked"
(( code == 130 )) && title="Watermark was interrupted"
if (( ${#saved} )); then
    answer=$(alert "$title" "${(F)lines}" "OK" "Reveal in Finder") || exit 0
    [[ $answer == "Reveal in Finder" ]] && reveal "${saved[@]}"
else
    alert "$title" "${(F)lines}" >/dev/null
fi
exit 0
