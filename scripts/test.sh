#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
developer_dir="$(xcode-select -p)"
testing_dir="$developer_dir/Library/Developer"
if [[ -d "$testing_dir/Frameworks/Testing.framework" ]]; then
    # Standalone Command Line Tools ship Testing but SwiftPM does not currently
    # add its framework/interoperability search paths automatically.
    swift test --disable-xctest \
        -Xswiftc -F -Xswiftc "$testing_dir/Frameworks" \
        -Xlinker "-F$testing_dir/Frameworks" \
        -Xlinker -rpath -Xlinker "$testing_dir/Frameworks" \
        -Xlinker -rpath -Xlinker "$testing_dir/usr/lib" "$@"
else
    swift test --disable-xctest "$@"
fi
