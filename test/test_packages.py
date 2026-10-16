"""Offline provisioning contract tests; no host package-manager invocation."""
import os
import re
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/packages.sh"


class PackagesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.release = self.directory / "os-release"
        self.release.write_text('ID=debian\nVERSION_ID="13"\n')
        self.marker = self.directory / "manager-invoked"
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        for name in ("apt-get", "dnf", "pacman", "brew", "sudo", "curl", "wget"):
            self.stub(name, f'touch "{self.marker}"; exit 99')
        self.env = dict(os.environ, PACKAGES_TESTING="1",
                        PACKAGES_TEST_OS="Linux", PACKAGES_TEST_ARCH="x86_64",
                        PACKAGES_TEST_OS_RELEASE=str(self.release),
                        PATH=f"{self.bin}:{os.environ['PATH']}")

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/sh\n{body}\n")
        path.chmod(0o755)

    def run_script(self, *args, ok=True):
        result = subprocess.run(["bash", str(SCRIPT), *args], env=self.env,
                                text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.marker.exists(), "host mutation/network attempted")
        return result.stdout + result.stderr

    def test_default_is_dev_dry_run(self):
        output = self.run_script()
        self.assertIn("Would run:", output)
        self.assertIn("apt-get install", output)
        self.assertIn("just", output)
        self.assertNotIn("antidote", output)

    def test_minimal(self):
        self.assertEqual(self.run_script("--profile", "minimal", "--list").splitlines(),
                         ["git", "stow", "zsh", "vim", "python3"])

    def test_apt_snapshot(self):
        listed = self.run_script("--list").splitlines()
        self.assertEqual(listed, (ROOT / "Aptfile").read_text().split())
        self.assertEqual(len(listed), len(set(listed)))
        self.assertNotIn("starship", listed)

    def test_manager_mappings(self):
        for manager, present, absent in (("apt", "fd-find", "starship"),
                                         ("dnf", "vim-enhanced", "python3-venv"),
                                         ("pacman", "github-cli", "gh"),
                                         ("brew", "fd", "antidote")):
            with self.subTest(manager=manager):
                packages = self.run_script("--manager", manager, "--list").splitlines()
                self.assertIn(present, packages)
                self.assertNotIn(absent, packages)

    def test_manifest_schema_and_brew_policy(self):
        rows = [line.split() for line in (ROOT / "packages/cli.tsv").read_text().splitlines()
                if line and not line.startswith("#")]
        for row in rows:
            self.assertEqual(len(row), 6)
            self.assertIn(row[0], ("minimal", "dev"))
            self.assertTrue(all(re.fullmatch(r"[a-z0-9-]+", value) for value in row))
        base = (ROOT / "Brewfile").read_text()
        self.assertIn("packages/cli.tsv", base)
        self.assertNotIn('brew "antidote"', base)
        personal = (ROOT / "packages/Brewfile.personal").read_text()
        self.assertLess(personal.index('if RUBY_PLATFORM.include?("darwin")'),
                        personal.index('brew "mas"'))
        self.assertFalse((ROOT / "Brewfile.lock.json").exists())

    def test_supported_distros_and_wsl_metadata(self):
        for distro, version, manager in (("debian", "13", "apt-get"),
                                         ("ubuntu", "24.04", "apt-get"),
                                         ("ubuntu", "26.04", "apt-get"),
                                         ("fedora", "43", "dnf"),
                                         ("fedora", "44", "dnf"),
                                         ("arch", "", "pacman")):
            self.release.write_text(f'ID={distro}\nVERSION_ID="{version}"\n')
            self.assertIn(manager, self.run_script())
        self.env["PACKAGES_TEST_ARCH"] = "aarch64"
        self.assertIn("pacman", self.run_script())

    def test_unsupported_fails_closed(self):
        for distro, version in (("debian", "12"), ("ubuntu", "22.04"),
                                ("fedora", "42"), ("unknown", "99")):
            self.release.write_text(f'ID={distro}\nVERSION_ID="{version}"\n')
            self.run_script(ok=False)
        self.env["PACKAGES_TEST_OS"] = "Darwin"
        self.env["PACKAGES_TEST_ARCH"] = "mips"
        self.assertIn("architecture", self.run_script(ok=False))

    def test_metadata_is_not_executed(self):
        self.release.write_text(f'ID=$(touch {self.marker})\nVERSION_ID=13\n')
        self.run_script(ok=False)

    def test_invalid_arguments_are_not_executed(self):
        for args in (("--profile", f"$(touch {self.marker})"),
                     ("--manager", "apt;false"), ("--profile",), ("--bogus",)):
            self.run_script(*args, ok=False)

    def test_test_seam_cannot_install(self):
        self.assertIn("cannot install", self.run_script("--install", ok=False))
        self.env.pop("PACKAGES_TESTING")
        self.assertIn("cannot install", self.run_script("--manager", "apt", "--install", ok=False))

    def test_macos_profile_bundles(self):
        self.env["PACKAGES_TEST_OS"] = "Darwin"
        self.env["PACKAGES_TEST_ARCH"] = "arm64"
        dev = self.run_script()
        self.assertIn("brew install", dev)
        self.assertNotIn("brew bundle", dev)
        self.assertNotIn("sudo", dev)
        desktop = self.run_script("--profile", "desktop")
        self.assertIn("Brewfile.desktop", desktop)
        self.assertNotIn("Brewfile.personal", desktop)
        personal = self.run_script("--profile", "personal")
        self.assertIn("Brewfile.desktop", personal)
        self.assertIn("Brewfile.personal", personal)

    def test_linux_personal_only_adds_cli(self):
        self.assertIn("macOS-only", self.run_script("--profile", "personal"))

    def test_doctor_checks_neovim_version(self):
        # All dev commands resolve to stubs, including fd's Debian executable alias.
        for name in ("git", "stow", "zsh", "vim", "python3", "fzf", "fdfind",
                     "rg", "gh", "nano", "just", "pip3", "unzip", "gcc", "htop", "http", "git-lfs", "ps"):
            self.stub(name, "exit 0")
        for version in ("0.9.5", "0.10.4", "0.11.0", "0.11.2", "garbage"):
            self.stub("nvim", f"echo 'NVIM v{version}'")
            self.assertIn("Neovim >=0.11.3 required", self.run_script("--doctor", ok=False))
        for version in ("0.11.3", "0.11.6", "0.12.0-dev", "1.0.0"):
            self.stub("nvim", f"echo 'NVIM v{version}'")
            self.assertNotIn("Neovim >=0.11.3 required", self.run_script("--doctor"))

    def test_fedora_does_not_require_optional_third_party_repositories(self):
        self.assertNotIn('starship', self.run_script('--manager', 'dnf', '--list').splitlines())

    def test_fedora_keeps_an_existing_curl_provider(self):
        output = self.run_script('--manager', 'dnf', '--dry-run')
        command = next(line for line in output.splitlines() if 'dnf install' in line)
        self.assertNotIn('curl', command.split())
        self.assertIn('curl', self.run_script('--manager', 'dnf', '--list').splitlines())

    def test_container_uses_canonical_mapping(self):
        dockerfile = (ROOT / ".devcontainer/Dockerfile").read_text()
        self.assertIn("COPY packages/", dockerfile)
        self.assertIn("packages.sh --install --profile dev", dockerfile)
        self.assertNotIn("curl -fsSL", dockerfile)
        self.assertNotIn("git clone", dockerfile)


if __name__ == "__main__":
    unittest.main()
