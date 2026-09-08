#!/usr/bin/env python3
"""Exercise release failure boundaries without creating GitHub releases."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location("release", Path(__file__).with_name("prepare-release.py"))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)
REVISION = "a" * 40


class ReleaseTests(unittest.TestCase):
    def test_version_mismatch_prevents_any_command(self):
        with patch.object(release, "run") as run:
            with self.assertRaisesRegex(ValueError, "does not match"):
                release.prepare("999.0.0", REVISION, "owner/repo")
            run.assert_not_called()

    def test_revision_must_be_immutable(self):
        with self.assertRaisesRegex(ValueError, "40-character"):
            release.validate_checkout("2.0.0", "main")

    def test_existing_draft_or_tag_is_rejected(self):
        for responses in (["v2.0.0", ""], ["", "refs/tags/v2.0.0"]):
            with self.subTest(responses=responses), patch.object(release, "run", side_effect=responses):
                with self.assertRaisesRegex(ValueError, "already exists"):
                    release.ensure_new_release("owner/repo", "2.0.0")

    def test_api_failure_is_not_an_unused_tag(self):
        with patch.object(release, "run", side_effect=subprocess.CalledProcessError(1, "gh")):
            with self.assertRaises(subprocess.CalledProcessError):
                release.ensure_new_release("owner/repo", "2.0.0")

    def test_dirty_checkout_is_rejected(self):
        with patch.object(release, "run", side_effect=[REVISION, "?? uncommitted.swift"]):
            with self.assertRaisesRegex(ValueError, "clean committed"):
                release.validate_checkout("2.0.0", REVISION)

    def test_failed_tests_build_or_verification_never_create_release(self):
        for failing in ("scripts/test.sh", "scripts/build-dmg.sh", "scripts/verify-dmg.sh"):
            calls = []
            def execute(*args, **kwargs):
                calls.append(args)
                if args[0] == failing:
                    raise subprocess.CalledProcessError(1, args)
            with self.subTest(failing=failing), patch.object(release, "validate_checkout"), \
                 patch.object(release, "ensure_new_release"), patch.object(release, "run", side_effect=execute):
                with self.assertRaises(subprocess.CalledProcessError):
                    release.prepare("2.0.0", REVISION, "owner/repo")
                self.assertFalse(any(args[:3] == ("gh", "release", "create") for args in calls))

    def test_success_is_always_a_draft_with_exact_revision(self):
        calls = []
        def execute(*args, **kwargs):
            calls.append(args)
            return "abc123  installer.dmg" if args[0] == "shasum" else ""
        with patch.object(release, "validate_checkout"), patch.object(release, "ensure_new_release"), \
             patch.object(release, "run", side_effect=execute):
            release.prepare("2.0.0", REVISION, "owner/repo")
        create = next(args for args in calls if args[:3] == ("gh", "release", "create"))
        self.assertIn("--draft", create)
        self.assertEqual(create[create.index("--target") + 1], REVISION)
        self.assertIn("--notes-file", create)


if __name__ == "__main__":
    unittest.main()
