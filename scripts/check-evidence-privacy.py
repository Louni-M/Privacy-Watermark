#!/usr/bin/env python3
"""Reject personal home paths in tracked text evidence without printing values."""

import re
import subprocess
import sys
from pathlib import Path


def main():
    root = Path(__file__).resolve().parent.parent
    paths = subprocess.check_output(
        ["git", "ls-files", "-z", "--", "docs/"], cwd=root
    ).decode().split("\0")
    home_path = re.compile(r"/(?:Users|home)/([^/\s\"'<>]+)")
    violations = []
    for path in filter(None, paths):
        file = root / path
        if file.suffix not in {".txt", ".md", ".json", ".csv", ".html"}:
            continue
        for number, line in enumerate(file.read_text().splitlines(), 1):
            if any(match[1] != "runner" for match in home_path.finditer(line)):
                violations.append(f"{path}:{number}: replace personal home paths with <workspace>")
    if violations:
        print("\n".join(violations), file=sys.stderr)
        return 1
    print("Published text evidence contains no personal home paths.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
