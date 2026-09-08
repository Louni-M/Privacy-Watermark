#!/usr/bin/env python3
"""Prepare a verified draft from a clean checkout; never publish a release."""
import argparse
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def run(*args, capture=False, env=None):
    result = subprocess.run(args, cwd=ROOT, check=True, text=True,
                            stdout=subprocess.PIPE if capture else None, env=env)
    return result.stdout.strip() if capture else None


def validate_checkout(version, revision):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError("Version must be MAJOR.MINOR.PATCH, without a v prefix.")
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Source revision must be a full, lowercase 40-character commit SHA.")
    with (ROOT / "scripts/Info.plist").open("rb") as source:
        actual = plistlib.load(source)["CFBundleShortVersionString"]
    if version != actual:
        raise ValueError(f"Requested version {version} does not match app version {actual}.")
    if run("git", "rev-parse", "HEAD", capture=True) != revision:
        raise ValueError("Checkout does not match the requested source revision.")
    if run("git", "status", "--porcelain", "--untracked-files=all", capture=True):
        raise ValueError("Release preparation requires a clean committed checkout, including packaging files.")


def ensure_new_release(repo, version):
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
        raise ValueError("Repository must be OWNER/REPO.")
    tag = "v" + version
    # Enumerating releases includes drafts. Failed API requests must fail closed,
    # rather than treating missing permissions or network errors as an unused tag.
    releases = run("gh", "api", "--paginate", f"repos/{repo}/releases?per_page=100",
                   "--jq", ".[].tag_name", capture=True).splitlines()
    refs = run("gh", "api", f"repos/{repo}/git/matching-refs/tags/{tag}",
               "--jq", ".[].ref", capture=True).splitlines()
    if tag in releases or f"refs/tags/{tag}" in refs:
        raise ValueError(f"{tag} already exists; refusing to overwrite a tag or release.")


def prepare(version, revision, repo):
    validate_checkout(version, revision)
    ensure_new_release(repo, version)
    # A unique ignored output directory prevents stale binaries from being uploaded.
    (ROOT / "dist").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="release-", dir=ROOT / "dist") as output:
        env = dict(os.environ, OUTPUT_DIR=output)
        run("scripts/test.sh")
        run("scripts/build-dmg.sh", env=env)
        dmg = str(Path(output) / "Passport-Filigrane.dmg")
        run("scripts/verify-dmg.sh", dmg, version)
        validate_checkout(version, revision)
        ensure_new_release(repo, version)
        digest = run("shasum", "-a", "256", dmg, capture=True).split()[0]
        notes = Path(output) / "release-notes.md"
        notes.write_text(
            f"Passport Filigrane {version}\n\n"
            "CANDIDATE — manual downloaded-install acceptance is still required before publication.\n\n"
            f"Source revision: `{revision}`\n\nDMG SHA-256: `{digest}`\n\n"
            + (ROOT / "assets/dmg/Install.txt").read_text()
        )
        # --draft is unconditional. gh reports failed uploads as errors; any
        # partially created draft is explicitly a candidate, never ready/published.
        run("gh", "release", "create", "v" + version, dmg,
            "--repo", repo, "--target", revision, "--draft",
            "--title", f"Passport Filigrane {version}", "--notes-file", str(notes))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("revision")
    parser.add_argument("--repo", default=os.environ.get("GH_REPO", "Louni-M/Privacy-Watermark"))
    parser.add_argument("--check-only", action="store_true", help="Validate checkout and unused tag without building or writing to GitHub")
    args = parser.parse_args()
    try:
        if args.check_only:
            validate_checkout(args.version, args.revision)
            ensure_new_release(args.repo, args.version)
        else:
            prepare(args.version, args.revision, args.repo)
    except (ValueError, subprocess.CalledProcessError) as error:
        print(f"Release preparation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
