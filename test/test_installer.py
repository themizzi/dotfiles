"""Installer safety tests; no network, external Python packages or real HOME."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ['gh', 'gh-copilot', 'nano', 'nvim', 'starship', 'vim', 'zsh']
REAL_STOW = shutil.which('stow')


class InstallerFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='installer tests ')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'repo with spaces'
        self.repo.mkdir()
        shutil.copy2(ROOT / 'install.sh', self.repo / 'install.sh')
        for package in PACKAGES:
            directory = self.repo / package
            directory.mkdir()
            (directory / ('.' + package)).write_text(package)
        self.home = self.base / 'home with spaces'
        self.home.mkdir()
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.log = self.base / 'calls.jsonl'
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin),
                        CALL_LOG=str(self.log), SUBMODULE_STATUS=' ready zsh/.antidote')
        # Limit PATH so dependency tests do not depend on host installations.
        for name in ('dirname', 'cat', 'grep'):
            (self.bin / name).symlink_to(shutil.which(name))
        self.script('git', """import os, sys
assert sys.argv[1:] == ['-C', os.getcwd(), 'submodule', 'status', '--recursive']
print(os.environ['SUBMODULE_STATUS'])
sys.exit(int(os.environ.get('GIT_FAILURE', '0')))
""")
        self.script('stow', """import json, os, sys
with open(os.environ['CALL_LOG'], 'a') as output:
    output.write(json.dumps(sys.argv[1:]) + '\\n')
sys.exit(int(os.environ.get('STOW_FAILURE', '0')))
""")

    def script(self, name, contents):
        import sys
        path = self.bin / name
        path.write_text('#!' + sys.executable + '\n' + contents)
        path.chmod(0o755)

    def run_installer(self, *args):
        return subprocess.run(['/bin/sh', str(self.repo / 'install.sh'), *args],
                              cwd=self.base, env=self.env, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def snapshot(self):
        return sorted((str(p.relative_to(self.home)),
                       ('link', os.readlink(p)) if p.is_symlink() else
                       ('dir', '') if p.is_dir() else ('file', p.read_bytes()))
                      for p in self.home.rglob('*'))


class InstallerTests(InstallerFixture):
    def test_help_and_invalid_options_need_no_dependencies(self):
        (self.bin / 'stow').unlink()
        (self.bin / 'git').unlink()
        self.assertEqual(self.run_installer('--help').returncode, 0)
        self.assertNotEqual(self.run_installer('--adopt').returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_missing_dependencies(self):
        for dependency in ('stow', 'git'):
            with self.subTest(dependency=dependency):
                path = self.bin / dependency
                contents = path.read_bytes()
                path.unlink()
                result = self.run_installer()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('required', result.stderr)
                self.assertEqual(self.calls(), [])
                path.write_bytes(contents)
                path.chmod(0o755)

    def test_submodule_failures_do_not_call_stow(self):
        for status in ('-abc zsh/.antidote', 'Uabc nano/nanorc.d', ''):
            with self.subTest(status=status):
                self.env['SUBMODULE_STATUS'] = status
                result = self.run_installer('--dry-run')
                self.assertNotEqual(result.returncode, 0)
                if status:
                    self.assertIn('submodule update --init --recursive', result.stderr)
                self.assertEqual(self.calls(), [])
                self.assertEqual(self.snapshot(), [])
        self.env['GIT_FAILURE'] = '1'
        self.assertNotEqual(self.run_installer().returncode, 0)

    def test_cwd_spaces_preflight_then_apply(self):
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        preflight, apply = self.calls()
        self.assertIn('--dir=' + str(self.repo), apply)
        self.assertIn('--target=' + str(self.home), apply)
        self.assertEqual(apply[-7:], PACKAGES)
        self.assertIn('--stow', apply)
        self.assertNotIn('--restow', apply)
        self.assertNotIn('--adopt', apply)
        self.assertEqual(preflight, apply[:3] + ['--simulate'] + apply[3:])

    def test_dry_run_preserves_home(self):
        (self.home / '.vim').write_text('my configuration')
        before = self.snapshot()
        result = self.run_installer('--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('--simulate', self.calls()[0])
        self.assertEqual(self.snapshot(), before)

    def test_conflict_stops_before_apply(self):
        (self.home / '.vim').write_text('valuable')
        before = self.snapshot()
        self.env['STOW_FAILURE'] = '1'
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('preflight failed', result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.snapshot(), before)

    def test_unlink_does_not_require_git_or_submodules(self):
        (self.bin / 'git').unlink()
        result = self.run_installer('--unlink')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 2)
        self.assertTrue(all('--delete' in call for call in self.calls()))

    def test_unlink_dry_run(self):
        result = self.run_installer('--unlink', '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('--delete', self.calls()[0])

    def test_ambient_stow_configuration_is_rejected(self):
        for directory in (self.home, self.repo):
            with self.subTest(directory=directory):
                config = directory / '.stowrc'
                config.write_text('--adopt\n--override=.*\n')
                result = self.run_installer()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Stow options file', result.stderr)
                self.assertEqual(config.read_text(), '--adopt\n--override=.*\n')
                config.unlink()
        self.assertEqual(self.calls(), [])

    def test_missing_package_and_invalid_home(self):
        (self.repo / 'gh' / '.gh').unlink()
        (self.repo / 'gh').rmdir()
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.env['HOME'] = 'relative'
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.env['HOME'] = ''
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_malformed_venv_is_preserved_before_setup(self):
        directory = self.repo / '.devcontainer' / 'scripts'
        directory.mkdir(parents=True)
        script = directory / 'post-create.sh'
        shutil.copy2(ROOT / '.devcontainer' / 'scripts' / 'post-create.sh', script)
        venv = self.repo / '.venv'
        for kind in ('directory', 'file', 'dangling link'):
            with self.subTest(kind=kind):
                if kind == 'directory':
                    venv.mkdir()
                    (venv / 'valuable').write_text('keep')
                elif kind == 'file':
                    venv.write_text('keep')
                else:
                    venv.symlink_to(self.repo / 'missing')
                result = subprocess.run(['/bin/sh', str(script)], env=self.env,
                                        text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('has not been deleted', result.stderr)
                if kind == 'directory':
                    self.assertEqual((venv / 'valuable').read_text(), 'keep')
                    (venv / 'valuable').unlink()
                    venv.rmdir()
                elif kind == 'file':
                    self.assertEqual(venv.read_text(), 'keep')
                    venv.unlink()
                else:
                    self.assertTrue(venv.is_symlink())
                    venv.unlink()


@unittest.skipUnless(REAL_STOW, 'GNU Stow not installed; stub coverage runs above')
class RealStowTests(InstallerFixture):
    def setUp(self):
        super().setUp()
        (self.bin / 'stow').unlink()
        (self.bin / 'stow').symlink_to(REAL_STOW)

    # Inherit fixture helpers, not the stub protocol assertions.
    def test_real_idempotence_dry_run_and_unlink(self):
        self.assertEqual(self.run_installer('--dry-run').returncode, 0)
        self.assertEqual(self.snapshot(), [])
        for _ in range(2):
            result = self.run_installer()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / '.vim').is_symlink())
        (self.home / 'unrelated').write_text('keep')
        before = self.snapshot()
        self.assertEqual(self.run_installer('--unlink', '--dry-run').returncode, 0)
        self.assertEqual(self.snapshot(), before)
        for _ in range(2):
            result = self.run_installer('--unlink')
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / 'unrelated').read_text(), 'keep')
        self.assertFalse((self.home / '.vim').is_symlink())

    def test_real_conflict_is_atomic(self):
        (self.home / '.vim').write_text('keep')
        before = self.snapshot()
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.snapshot(), before)


if __name__ == '__main__':
    unittest.main()
