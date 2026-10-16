"""Offline task contracts; all execution uses disposable repositories/homes."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
JUST = shutil.which("just")


class TaskContracts(unittest.TestCase):
    def test_public_recipes(self):
        text = (ROOT / "justfile").read_text()
        for recipe in ("install *args:", "check:", "test-installer *args:", "test:"):
            self.assertIn(recipe, text)
        self.assertIn('sh install.sh "$@"', text)
        self.assertIn('sh scripts/test-installer.sh "$@"', text)
        self.assertIn(".venv/bin/python", text)
        self.assertIn("-m unittest discover", text)
        self.assertNotIn("pip install", text)
        self.assertFalse((ROOT / "Makefile").exists())

    def test_package_declarations(self):
        self.assertIn('brew "just"', (ROOT / "Brewfile").read_text().splitlines())
        self.assertIn("just", (ROOT / "Aptfile").read_text().splitlines())
        self.assertIn("        just \\", (ROOT / ".devcontainer/Dockerfile").read_text())


class SandboxedTasks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="just contracts ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copy(ROOT / "justfile", self.root)
        (self.root / "scripts").mkdir()
        shutil.copy(ROOT / "scripts/check.sh", self.root / "scripts")
        shutil.copy(ROOT / "scripts/test-installer.sh", self.root / "scripts")
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")

    def run_just(self, *args):
        if JUST is None:
            self.skipTest("Just not available")
        return subprocess.run(
            [JUST, *args], cwd=self.root, env=self.env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

    def test_install_argument_boundaries_and_no_interpolation(self):
        # A fixture entry point, not the real installer: never touch HOME.
        (self.root / "install.sh").write_text(
            'printf "%s\\n" "$#" "$@"\n'
        )
        args = ["two words", "$(touch BAD)", "quote'\"", "", "--flag"]
        result = self.run_just("install", *args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [str(len(args)), *args])
        self.assertFalse((self.root / "BAD").exists())

    def test_missing_venv_diagnostic(self):
        result = self.run_just("test")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing .venv/bin/python", result.stderr)

    def test_installer_recipe_forwards_arguments_without_python(self):
        (self.root / 'scripts/test-installer.sh').write_text('printf "%s\\n" "$#" "$@"\n')
        args = ['--filter', 'paths with spaces', '$(touch BAD)']
        result = self.run_just('test-installer', *args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [str(len(args)), *args])
        self.assertFalse((self.root / 'BAD').exists())

    def test_test_recipe_uses_local_python_and_orders_suites(self):
        # A fake interpreter records invocation without importing dependencies.
        python = self.root / ".venv/bin/python"
        python.parent.mkdir(parents=True)
        python.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> calls\n')
        python.chmod(0o755)
        (self.root / "test").mkdir()
        (self.root / 'scripts/test-installer.sh').write_text('printf "Bats\\n" >> calls\n')
        tools = self.root / "tools"
        tools.mkdir()
        for name in ("nvim", "stow", "zsh"):
            tool = tools / name
            tool.write_text("#!/bin/sh\nexit 0\n")
            tool.chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]
        result = self.run_just("test")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = (self.root / "calls").read_text().splitlines()
        self.assertEqual(calls[0], 'Bats')
        self.assertIn('-B -m unittest discover', calls[1])
        self.assertEqual(len(calls), 2)

    def test_standard_library_tests_need_no_site_packages(self):
        python = self.root / ".venv/bin/python"
        python.parent.mkdir(parents=True)
        # -S excludes installed third-party packages, without needing a venv.
        python.write_text('#!/bin/sh\nexec "$TEST_PYTHON" -S "$@"\n')
        python.chmod(0o755)
        self.env["TEST_PYTHON"] = sys.executable
        (self.root / 'scripts/test-installer.sh').write_text('exit 0\n')
        (self.root / 'test').mkdir()
        (self.root / 'test/test_example.py').write_text('import unittest\nclass Example(unittest.TestCase):\n    def test_ok(self): self.assertTrue(True)\n')
        tools = self.root / 'tools'
        tools.mkdir()
        for name in ('nvim', 'stow', 'zsh'):
            tool = tools / name
            tool.write_text('#!/bin/sh\nexit 0\n')
            tool.chmod(0o755)
        self.env['PATH'] = str(tools) + os.pathsep + self.env['PATH']
        result = self.run_just("test")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Ran 1 test', result.stderr)

    def test_check_syntax_only_and_invalid_inputs(self):
        for executable in ("git", "sh", "zsh", "python3"):
            if not shutil.which(executable):
                self.skipTest(f"{executable} not available")
        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        (self.root / "space name.sh").write_text("touch SHOULD_NOT_EXIST\n")
        (self.root / ".zshrc").write_text("touch SHOULD_NOT_EXIST\n")
        (self.root / "module.py").write_text("raise RuntimeError('do not import')\n")
        (self.root / "data.json").write_text(json.dumps({"valid": True}))
        before = {p.relative_to(self.root): p.read_bytes()
                  for p in self.root.rglob("*") if p.is_file()}
        result = self.run_just("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        after = {p.relative_to(self.root): p.read_bytes()
                 for p in self.root.rglob("*") if p.is_file()}
        self.assertEqual(before, after)
        for name, text in (("bad.sh", "if\n"), ("bad.zsh", "if\n"),
                           ("bad.json", "{"), ("bad.py", "def :\n")):
            with self.subTest(name=name):
                path = self.root / name
                path.write_text(text)
                result = self.run_just("check")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(name, result.stderr)
                path.unlink()

    def test_check_missing_executable_diagnostic(self):
        # Call the checker directly with a PATH containing only sh.
        tools = self.root / "tools"
        tools.mkdir()
        (tools / "sh").symlink_to(shutil.which("sh"))
        self.env["PATH"] = str(tools)
        result = subprocess.run(
            [str(tools / "sh"), "scripts/check.sh"], cwd=self.root, env=self.env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required executable not found in PATH: zsh", result.stderr)


if __name__ == "__main__":
    unittest.main()
