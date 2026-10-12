#!/usr/bin/env python3
"""Exercise the Finder Quick Action scripts with stubbed dialogs and a temporary HOME.

osascript is replaced by a stub that records each dialog and answers from a
script; pwm is a wrapper that records its exact arguments, then runs the real
binary built from this checkout, so files are really watermarked.
"""
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
QUICK_ACTION = ROOT / "scripts" / "quick-action"
FIXTURES = ROOT / "tests" / "WatermarkCoreTests" / "Fixtures"
ACCENTED = "Dossier location — Agence Hôtel-de-Ville"

OSASCRIPT = r'''#!/usr/bin/env python3
import json, os, sys
script = sys.stdin.read()
kind = next(k for k, marker in [("list", "choose from list"), ("dialog", "display dialog"), ("alert", "display alert"),
             ("notification", "display notification"), ("reveal", "reveal theItems")] if marker in script)
args = [a for a in sys.argv[1:] if a != "-"]
with open(os.environ["STUB_LOG"], "a", encoding="utf-8") as log:
    log.write(json.dumps({"kind": kind, "argv": args}) + "\n")
state = os.environ["STUB_STATE"]
replies = json.load(open(state, encoding="utf-8"))
answer = replies.get(kind)
if isinstance(answer, list):
    answer = answer.pop(0) if answer else None
    json.dump(replies, open(state, "w", encoding="utf-8"))
if answer == "CANCEL":
    sys.stderr.write("execution error: User canceled. (-128)\n"); sys.exit(1)
if kind == "dialog":
    button, text = answer
    sys.stdout.buffer.write((button + "\n" + text + "\n").encode())
elif kind in ("list", "alert"):
    sys.stdout.buffer.write(((answer or "") + "\n").encode())
'''

PWM_WRAPPER = r'''#!/usr/bin/env python3
import json, os, sys
with open(os.environ["PWM_LOG"], "a", encoding="utf-8") as log:
    log.write(json.dumps([os.fsencode(a).hex() for a in sys.argv[1:]]) + "\n")
os.execv(os.environ["REAL_PWM"], [os.environ["REAL_PWM"]] + sys.argv[1:])
'''


def executable(path, text):
    path.write_text(text, encoding="utf-8")
    path.chmod(0o755)
    return path


def snapshot(root):
    """Every path below root with its type and contents, to prove nothing else changed."""
    result = {}
    for path in sorted(Path(root).rglob("*")):
        key = str(path.relative_to(root))
        if path.is_symlink():
            result[key] = "link:" + os.readlink(path)
        elif path.is_dir():
            result[key] = "dir"
        else:
            result[key] = path.read_bytes()
    return result


class QuickActionCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.run(["swift", "build", "--product", "pwm"], cwd=ROOT, check=True, capture_output=True)
        bin_path = subprocess.run(["swift", "build", "--show-bin-path"], cwd=ROOT, check=True,
                                  capture_output=True, text=True).stdout.strip()
        cls.real_pwm = Path(bin_path) / "pwm"

    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="quick-action-")).resolve()
        self.addCleanup(shutil.rmtree, self.root, True)
        self.home = self.root / "home"
        for folder in ("home", "stubs", "apps", "tmp", "config", "docs"):
            (self.root / folder).mkdir()
        executable(self.root / "stubs" / "osascript", OSASCRIPT)
        self.pwm = executable(self.root / "stubs" / "pwm", PWM_WRAPPER)
        self.log = self.root / "dialogs.log"
        self.pwm_log = self.root / "pwm.log"
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.root / 'stubs'}:/usr/bin:/bin", "LC_ALL": "C",
            "TMPDIR": str(self.root / "tmp"), "XDG_CONFIG_HOME": str(self.root / "config"),
            "WATERMARK_APP_LOCATIONS": str(self.root / "apps"), "STUB_LOG": str(self.log),
            "STUB_STATE": str(self.root / "replies.json"), "PWM_LOG": str(self.pwm_log), "REAL_PWM": str(self.real_pwm),
            "PYTHONDONTWRITEBYTECODE": "1",
        }

    def install(self, *arguments, check=True):
        result = subprocess.run([str(QUICK_ACTION / "install.sh"), "--pwm", str(self.pwm), *arguments],
                                env=self.env, capture_output=True, text=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def uninstall(self):
        return subprocess.run([str(QUICK_ACTION / "uninstall.sh")], env=self.env, capture_output=True, text=True)

    @property
    def workflow(self):
        return self.home / "Library" / "Services" / "Watermark.workflow"

    def document(self, name, fixture):
        target = self.root / "docs" / name
        shutil.copyfile(FIXTURES / fixture, target)
        return target

    def run_quick_action(self, files, replies):
        """Runs the workflow's own launcher, as Automator does, with files as arguments."""
        (self.root / "replies.json").write_text(json.dumps(replies), encoding="utf-8")
        wflow = plistlib.loads((self.workflow / "Contents" / "document.wflow").read_bytes())
        launcher = wflow["actions"][0]["action"]["ActionParameters"]["COMMAND_STRING"]
        result = subprocess.run(["/bin/zsh", "-c", launcher, "Watermark", *map(str, files)],
                                env=self.env, capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def dialogs(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]

    def pwm_calls(self):
        if not self.pwm_log.exists():
            return []
        return [[bytes.fromhex(a).decode("utf-8") for a in json.loads(line)]
                for line in self.pwm_log.read_text(encoding="utf-8").splitlines()]

    def exports(self):
        return [call for call in self.pwm_calls() if call not in (["--version"], ["--list-presets"])
                and not (len(call) == 2 and call[0] == "--preset")]


class WatermarkScriptTests(QuickActionCase):
    def test_launcher_and_script_are_valid(self):
        subprocess.run(["zsh", "-n", str(QUICK_ACTION / "watermark.zsh")], check=True)
        for plist in ("Info.plist", "document.wflow"):
            subprocess.run(["plutil", "-lint", str(QUICK_ACTION / "Watermark.workflow" / "Contents" / plist)],
                           check=True, capture_output=True)
        info = plistlib.loads((QUICK_ACTION / "Watermark.workflow" / "Contents" / "Info.plist").read_bytes())
        service = info["NSServices"][0]
        self.assertEqual(service["NSMenuItem"]["default"], "Watermark")
        self.assertEqual(service["NSSendFileTypes"], ["public.jpeg", "public.png", "com.adobe.pdf"])
        self.assertEqual(service["NSRequiredContext"]["NSApplicationIdentifier"], "com.apple.finder")

    def test_accented_text_with_date_under_c_locale(self):
        self.install()
        photo, payslip = self.document("id.jpg", "photo.jpg"), self.document("payslip.pdf", "document.pdf")
        originals = [photo.read_bytes(), payslip.read_bytes()]
        self.run_quick_action([photo, payslip], {"dialog": [["With date", ACCENTED]]})
        exports = self.exports()
        self.assertEqual(len(exports), 1)
        self.assertEqual(exports[0][:3], ["--text", ACCENTED, "--date"])
        self.assertEqual(exports[0][3:], ["--", str(photo), str(payslip)])
        self.assertTrue((self.root / "docs" / "id_watermarked.jpg").is_file())
        self.assertTrue((self.root / "docs" / "payslip_watermarked.pdf").is_file())
        self.assertEqual([photo.read_bytes(), payslip.read_bytes()], originals)
        shown = self.dialogs()
        self.assertEqual([d["kind"] for d in shown], ["dialog", "notification"])
        self.assertEqual(shown[0]["argv"][1], "", "the text field starts empty")
        self.assertEqual(shown[1]["argv"], ["2 copies saved beside the originals."])
        self.assertEqual(os.listdir(self.root / "tmp"), [])

    def test_without_date(self):
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        self.run_quick_action([photo], {"dialog": [["Without date", "COPY"]]})
        self.assertEqual(self.exports(), [["--text", "COPY", "--no-date", "--", str(photo)]])
        self.assertEqual(self.dialogs()[-1]["argv"], ["1 copy saved beside the originals."])

    def test_cancel_writes_nothing_and_shows_no_error(self):
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        before = snapshot(self.root / "docs")
        self.run_quick_action([photo], {"dialog": ["CANCEL"]})
        self.assertEqual([d["kind"] for d in self.dialogs()], ["dialog"])
        self.assertEqual(self.exports(), [])
        self.assertEqual(snapshot(self.root / "docs"), before)
        self.assertEqual(os.listdir(self.root / "tmp"), [])

    def test_missing_pwm_explains_and_processes_nothing(self):
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        self.pwm.unlink()
        before = snapshot(self.root / "docs")
        self.run_quick_action([photo], {"alert": "OK"})
        shown = self.dialogs()
        self.assertEqual([d["kind"] for d in shown], ["alert"])
        self.assertIn("Privacy Watermark is not installed", shown[0]["argv"][0])
        self.assertIn("install.sh", shown[0]["argv"][1])
        self.assertEqual(snapshot(self.root / "docs"), before)

    def test_app_moved_after_installation_uses_the_app_in_applications(self):
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        moved = self.root / "apps" / "Privacy Watermark.app" / "Contents" / "MacOS"
        moved.mkdir(parents=True)
        shutil.move(str(self.pwm), moved / "pwm")
        self.run_quick_action([photo], {"dialog": [["With date", "COPY"]]})
        self.assertTrue((self.root / "docs" / "id_watermarked.jpg").is_file())

    def test_partial_failure_lists_reasons_and_reveals_saved_copies(self):
        self.install()
        photo, locked = self.document("id.jpg", "photo.jpg"), self.document("locked.pdf", "protected.pdf")
        notes = self.root / "docs" / "notes.txt"
        notes.write_text("plain", encoding="utf-8")
        self.run_quick_action([photo, locked, notes], {"dialog": [["With date", ACCENTED]], "alert": "Reveal in Finder"})
        alert, reveal = self.dialogs()[1:]
        self.assertEqual(alert["kind"], "alert")
        title, message, *buttons = alert["argv"]
        self.assertEqual(title, "Some files were not watermarked")
        self.assertEqual(buttons, ["OK", "Reveal in Finder"])
        self.assertIn("Excluded: locked.pdf — This PDF is password-protected and cannot be opened.", message)
        self.assertIn("Excluded: notes.txt — Choose a JPG, PNG, or PDF file.", message)
        self.assertTrue(message.endswith("1 saved · 0 failed · 2 excluded · 0 not processed"))
        self.assertNotIn(str(self.root), message)
        self.assertNotIn("Hôtel", message)
        self.assertEqual(reveal["kind"], "reveal")
        self.assertEqual([os.path.realpath(p) for p in reveal["argv"]], [str(self.root / "docs" / "id_watermarked.jpg")])

    def test_nothing_saved_offers_no_reveal(self):
        self.install()
        locked = self.document("locked.pdf", "protected.pdf")
        self.run_quick_action([locked], {"dialog": [["With date", "COPY"]], "alert": "OK"})
        alert = self.dialogs()[-1]
        self.assertEqual(alert["argv"][0], "No file was watermarked")
        self.assertEqual(alert["argv"][2:], [])

    def test_text_over_the_limit_is_asked_again(self):
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        long_text = "x" * 195
        self.run_quick_action([photo], {"dialog": [["With date", long_text], ["Without date", "COPY"]]})
        first, second = [d for d in self.dialogs() if d["kind"] == "dialog"]
        self.assertIn("206 characters", second["argv"][0])
        self.assertIn("The maximum is 200", second["argv"][0])
        self.assertEqual(second["argv"][1], long_text, "the previous text is offered for editing")
        self.assertEqual(self.exports()[-1], ["--text", "COPY", "--no-date", "--", str(photo)])
        self.assertTrue((self.root / "docs" / "id_watermarked.jpg").is_file())
        self.assertFalse((self.root / "docs" / "id_watermarked (2).jpg").exists())

    def test_presets_are_offered_first(self):
        (self.root / "config" / "pwm").mkdir()
        (self.root / "config" / "pwm" / "presets.json").write_text(json.dumps({"presets": {
            "rental": {"text": "Rental application", "date": True, "opacity": 40},
            "plain": {"opacity": 50}}}), encoding="utf-8")
        self.install()
        photo = self.document("id.jpg", "photo.jpg")
        self.run_quick_action([photo], {"list": "rental"})
        shown = self.dialogs()
        self.assertEqual(shown[0], {"kind": "list", "argv": ["plain", "rental", "Custom text…"]})
        self.assertEqual([d["kind"] for d in shown], ["list", "notification"])
        self.assertEqual(self.exports(), [["--preset", "rental", "--", str(photo)]])

        # A preset without text asks for it, keeping the preset's settings.
        self.run_quick_action([photo], {"list": "plain", "dialog": [["Without date", "COPY"]]})
        self.assertEqual(self.exports()[-1], ["--preset", "plain", "--text", "COPY", "--no-date", "--", str(photo)])

        # Custom text skips the presets; cancelling the list writes nothing.
        self.run_quick_action([photo], {"list": "Custom text…", "dialog": [["With date", "COPY"]]})
        self.assertEqual(self.exports()[-1], ["--text", "COPY", "--date", "--", str(photo)])
        count = len(self.exports())
        self.run_quick_action([photo], {"list": "CANCEL"})
        self.assertEqual(len(self.exports()), count)


class InstallTests(QuickActionCase):
    def test_install_link_reinstall_and_uninstall_touch_only_their_files(self):
        (self.home / "notes.txt").write_text("unrelated", encoding="utf-8")
        (self.home / "Library" / "Services").mkdir(parents=True)
        other = self.home / "Library" / "Services" / "Other.workflow"
        other.mkdir()
        baseline = snapshot(self.home)

        result = self.install("--link")
        link = self.home / ".local" / "bin" / "pwm"
        self.assertEqual(os.readlink(link), str(self.pwm))
        self.assertIn("is not on your PATH", result.stdout)
        resources = self.workflow / "Contents" / "Resources"
        self.assertEqual((resources / "pwm-path").read_text().strip(), str(self.pwm))
        self.assertTrue(os.access(resources / "watermark.zsh", os.X_OK))
        self.assertEqual((resources / "watermark.zsh").read_bytes(), (QUICK_ACTION / "watermark.zsh").read_bytes())
        added = set(snapshot(self.home)) - set(baseline)
        self.assertTrue(all(p.startswith(("Library/Services/Watermark.workflow", ".local")) for p in added), added)
        self.assertEqual({k: v for k, v in snapshot(self.home).items() if k in baseline}, baseline)

        # Reinstall replaces only the Quick Action and keeps the earlier link.
        (resources / "stale").write_text("old", encoding="utf-8")
        self.env["PATH"] = f"{self.home / '.local' / 'bin'}:{self.env['PATH']}"
        result = self.install()
        self.assertFalse((resources / "stale").exists())
        self.assertEqual(os.readlink(link), str(self.pwm))
        self.assertNotIn("PATH", result.stdout)

        result = self.uninstall()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.workflow.exists())
        self.assertFalse(os.path.lexists(link))
        after = snapshot(self.home)
        self.assertEqual({k: v for k, v in after.items() if k in baseline}, baseline)
        self.assertEqual(set(after) - set(baseline), {".local", ".local/bin"})

    def test_custom_link_folder(self):
        folder = self.root / "bin"
        self.env["PATH"] = f"{folder}:{self.env['PATH']}"
        result = self.install("--link", str(folder))
        self.assertEqual(os.readlink(folder / "pwm"), str(self.pwm))
        self.assertNotIn("is not on your PATH", result.stdout)
        self.uninstall()
        self.assertFalse(os.path.lexists(folder / "pwm"))

    def test_foreign_files_are_never_replaced(self):
        foreign = self.workflow / "Contents"
        foreign.mkdir(parents=True)
        (foreign / "Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "com.example.watermark"}))
        before = snapshot(self.home)
        self.assertEqual(self.install(check=False).returncode, 1)
        self.assertEqual(self.uninstall().returncode, 1)
        self.assertEqual(snapshot(self.home), before)

        shutil.rmtree(self.workflow)
        bin_folder = self.home / ".local" / "bin"
        bin_folder.mkdir(parents=True)
        (bin_folder / "pwm").write_text("my own tool", encoding="utf-8")
        self.assertEqual(self.install("--link", check=False).returncode, 1)
        self.assertEqual((bin_folder / "pwm").read_text(encoding="utf-8"), "my own tool")
        self.assertFalse(self.workflow.exists())

    def test_scripts_need_no_administrator_rights_or_quarantine_changes(self):
        for name in ("install.sh", "uninstall.sh", "watermark.zsh"):
            text = (QUICK_ACTION / name).read_text(encoding="utf-8")
            for forbidden in ("sudo", "xattr", "spctl", "com.apple.quarantine"):
                self.assertNotIn(forbidden, text, f"{name} uses {forbidden}")
            self.assertTrue((QUICK_ACTION / name).stat().st_mode & stat.S_IXUSR, f"{name} is not executable")

    def test_missing_pwm_is_reported(self):
        self.pwm.unlink()
        result = self.install(check=False)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(self.workflow.exists())


if __name__ == "__main__":
    unittest.main()
