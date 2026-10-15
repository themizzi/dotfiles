"""Dependency-free contract tests for the POSIX Stow profile resolver."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-profiles-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / "profiles", self.root / "profiles")
        (self.root / "scripts").mkdir()
        shutil.copy2(
            ROOT / "scripts/profile-packages.sh",
            self.root / "scripts/profile-packages.sh",
        )

    def resolve(self, *args):
        return subprocess.run(
            ["sh", str(self.root / "scripts/profile-packages.sh"), *args],
            cwd="/",
            capture_output=True,
            text=True,
            check=False,
        )

    def append(self, name, text):
        with (self.root / "profiles" / (name + ".profile")).open("a") as file:
            file.write(text)

    def assert_invalid(self, result):
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertTrue(result.stderr)

    def test_exact_profiles(self):
        dev = ["gh", "nano", "nvim", "starship", "vim", "zsh"]
        expected = {
            "minimal": ["vim", "zsh"],
            "dev": dev,
            "desktop": dev,
            "personal": ["gh", "gh-copilot", "nano", "nvim", "starship", "vim", "zsh"],
        }
        for profile, packages in expected.items():
            with self.subTest(profile=profile):
                result = self.resolve("--profile", profile)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "\n".join(packages) + "\n")
                self.assertEqual(result.stderr, "")

    def test_default_is_dev(self):
        self.assertEqual(self.resolve().stdout, self.resolve("--profile", "dev").stdout)

    def test_duplicates_and_multiple_inheritance(self):
        self.append("dev", "extends minimal\npackage vim\npackage gh\n")
        self.append("personal", "extends minimal\nextends desktop\npackage gh-copilot\n")
        result = self.resolve("--profile", "personal")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout, "gh\ngh-copilot\nnano\nnvim\nstarship\nvim\nzsh\n"
        )

    def test_invalid_names_and_arguments(self):
        for name in ("", "unknown", "../dev", "DEV", "$(touch forbidden)", "dev\npersonal"):
            with self.subTest(name=name):
                self.assert_invalid(self.resolve("--profile", name))
        for args in (("dev",), ("--profile",), ("--other", "dev"), ("--profile", "dev", "extra")):
            with self.subTest(args=args):
                self.assert_invalid(self.resolve(*args))

    def test_cycle(self):
        self.append("minimal", "extends personal\n")
        self.assert_invalid(self.resolve("--profile", "personal"))

    def test_unknown_parent(self):
        self.append("dev", "extends missing\n")
        self.assert_invalid(self.resolve())

    def test_unsupported_package(self):
        self.append("desktop", "package desktop\n")
        self.assert_invalid(self.resolve())

    def test_shell_is_not_executed(self):
        marker = self.root / "executed"
        self.append("dev", "touch " + str(marker) + "\n")
        self.assert_invalid(self.resolve())
        self.assertFalse(marker.exists())

    def test_malformed_directive(self):
        self.append("minimal", "package vim extra\n")
        self.assert_invalid(self.resolve())

    def test_missing_definition(self):
        (self.root / "profiles/dev.profile").unlink()
        self.assert_invalid(self.resolve())

    def test_help(self):
        result = self.resolve("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Usage:", result.stdout)
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
