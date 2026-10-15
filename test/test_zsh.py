"""Real zsh startup in disposable homes, without user config or network."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ZSH = shutil.which("zsh")


@unittest.skipUnless(ZSH, "zsh is required")
class ZshStartupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-zsh-")
        self.addCleanup(self.tmp.cleanup)
        # Spaces catch unquoted paths in environment and plugin initialization.
        self.home = Path(self.tmp.name) / "test home"
        self.home.mkdir()
        for name in (".zshenv", ".zprofile", ".zshrc", ".zsh_plugins.txt"):
            shutil.copy2(ROOT / "zsh" / name, self.home / name)
        shutil.copytree(ROOT / "zsh" / ".zsh", self.home / ".zsh")
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.env = {
            "HOME": str(self.home), "ZDOTDIR": str(self.home),
            "PATH": f"{self.bin}:/usr/bin:/bin", "TERM": "dumb", "LC_ALL": "C",
            # Make an absent compatibility override deterministic on brew hosts.
            "DOTFILES_ANTIDOTE_HOMEBREW_PATH": "",
        }
        for tool in ("git", "curl", "wget"):
            self.write(self.bin / tool, '#!/bin/sh\necho "unexpected network tool" >&2\nexit 99\n', executable=True)

    def write(self, path, content, executable=False):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        if executable:
            path.chmod(0o700)
        return path

    def run_zsh(self, command, flags="-ic", extra=None):
        result = subprocess.run(
            [ZSH, "-d", flags, command], env={**self.env, **(extra or {})},
            cwd=self.home, text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stderr, "")
        return result.stdout.strip()

    def fake_brew(self):
        prefix = self.home / "brew prefix"
        self.write(self.bin / "brew", (
            '#!/bin/sh\n[ "$1" = shellenv ] || exit 1\n'
            'echo call >> "$HOME/brew-calls"\n'
            f'''printf "export HOMEBREW_PREFIX='%s'\\n" '{prefix}'\n'''
        ), executable=True)
        return prefix

    def fake_antidote(self, path, marker):
        self.write(path, f"""
ANTIDOTE_SELECTED={marker}
antidote() {{
  print -r -- "$1" >> "$HOME/antidote-calls"
  [[ $1 == bundle ]] || return 99
  print -r -- '_zsh_highlight() {{ :; }}'
}}
""")

    def test_noninteractive_environment_is_quiet_and_minimal(self):
        self.fake_brew()
        self.write(self.home / ".cargo/env", 'print -u2 "must not load cargo"\n')
        self.assertEqual(self.run_zsh(":", "-c"), "")
        self.assertFalse((self.home / "brew-calls").exists())
        self.assertFalse((self.home / ".local/state").exists())

    def test_explicit_xdg_values_survive_before_interactive_startup(self):
        extra = {key: str(self.home / key) for key in (
            "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME")}
        result = self.run_zsh(
            'print -rl -- "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" '
            '"$XDG_DATA_HOME" "$XDG_STATE_HOME" "$NANORC"', "-c", extra)
        self.assertEqual(result.splitlines(), list(extra.values()) + [extra["XDG_CONFIG_HOME"] + "/nano/nanorc"])

    def test_bare_interactive_startup_and_history(self):
        result = self.run_zsh(
            'print -r -- "$HISTFILE|$HISTSIZE|$SAVEHIST|$options[incappendhistory]|$options[histignoredups]"')
        self.assertEqual(result, f"{self.home}/.local/state/zsh/history|50000|10000|on|on")
        self.assertEqual((self.home / ".local/state/zsh").stat().st_mode & 0o777, 0o700)
        self.assertTrue((self.home / ".cache/zsh/zcompdump").is_file())

    def test_login_and_interactive_discover_one_brew_once(self):
        self.fake_brew()
        self.run_zsh('source ~/.zshrc; :', "-lic")
        self.assertEqual((self.home / "brew-calls").read_text().splitlines(), ["call"])

    def test_login_only_gets_tools_without_interactive_state(self):
        prefix = self.fake_brew()
        self.assertEqual(self.run_zsh('print -r -- "$HOMEBREW_PREFIX"', "-lc"), str(prefix))
        self.assertFalse((self.home / ".local/state/zsh").exists())

    def test_path_is_unique_and_optional_directories_must_exist(self):
        self.fake_brew()
        for name in (".local/bin", ".cargo/bin", "go/bin"):
            (self.home / name).mkdir(parents=True)
        result = self.run_zsh('source ~/.zshrc; print -rl -- $path', extra={
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/bin"})
        paths = result.splitlines()
        self.assertEqual(len(paths), len(set(paths)))
        for name in (".local/bin", ".cargo/bin", "go/bin"):
            self.assertIn(str(self.home / name), paths)
        self.assertNotIn(str(self.home / ".lmstudio/bin"), paths)
        self.assertNotIn("/opt/homebrew/opt/rustup/bin", paths)
        self.assertNotIn("/Users/themizzi/.docker/completions", paths)

    def test_editor_and_browser_overrides_are_preserved(self):
        self.assertEqual(self.run_zsh('print -r -- "$EDITOR|$VISUAL|$BROWSER"', extra={
            "EDITOR": "my-editor --wait", "VISUAL": "my-visual", "BROWSER": "desktop-browser"}),
            "my-editor --wait|my-visual|desktop-browser")

    def test_editor_falls_back_to_available_tool(self):
        self.write(self.bin / "nvim", "#!/bin/sh\nexit 0\n", executable=True)
        self.assertEqual(self.run_zsh('print -r -- "$EDITOR|$VISUAL"'), "nvim|nvim")

    def test_canonical_antidote_wins_and_startup_never_bundles(self):
        self.fake_antidote(self.home / ".antidote/antidote.zsh", "canonical")
        fallback = self.home / "compatibility/antidote.zsh"
        self.fake_antidote(fallback, "compatibility")
        self.assertEqual(self.run_zsh('print -r -- "$ANTIDOTE_SELECTED"', extra={
            "DOTFILES_ANTIDOTE_HOMEBREW_PATH": str(fallback)}), "canonical")
        self.assertFalse((self.home / "antidote-calls").exists())

    def test_explicit_compatibility_path_and_offline_cache(self):
        fallback = self.home / "compatibility/antidote.zsh"
        self.fake_antidote(fallback, "compatibility")
        extra = {"DOTFILES_ANTIDOTE_HOMEBREW_PATH": str(fallback)}
        self.run_zsh('dotfiles-plugins-update', extra=extra)
        self.assertEqual((self.home / "antidote-calls").read_text().splitlines(), ["bundle"])
        fallback.unlink()
        self.assertEqual(self.run_zsh('whence -w _zsh_highlight', extra=extra), "_zsh_highlight: function")
        self.assertEqual((self.home / "antidote-calls").read_text().splitlines(), ["bundle"])

    def test_selected_homebrew_antidote_fallback(self):
        prefix = self.fake_brew()
        self.fake_antidote(prefix / "opt/antidote/share/antidote/antidote.zsh", "brew")
        del self.env["DOTFILES_ANTIDOTE_HOMEBREW_PATH"]
        self.assertEqual(self.run_zsh('print -r -- "$ANTIDOTE_SELECTED"'), "brew")

    def test_failed_bundle_preserves_previous_cache(self):
        bundle = self.write(self.home / ".cache/zsh/plugins.zsh", "# previous bundle\n")
        self.write(self.home / ".antidote/antidote.zsh", "antidote() { print broken; return 1; }\n")
        self.run_zsh('if dotfiles-plugins-update; then exit 9; fi')
        self.assertEqual(bundle.read_text(), "# previous bundle\n")
        self.assertEqual(list(bundle.parent.glob("plugins.zsh.*")), [])

    def test_completion_paths_registered_before_single_compinit(self):
        completion_dir = self.home / "plugin completions"
        self.write(completion_dir / "_dotfiles_probe", "#compdef dotfiles-probe\n_arguments '*:args:'\n")
        self.write(self.home / ".cache/zsh/plugins.zsh", f"""
fpath=('{completion_dir}' $fpath)
_dotfiles_alias() {{ :; }}
compdef _dotfiles_alias 'probe with spaces'
""")
        # Wrapping autoloaded compinit records every invocation, not just the
        # final state of compdef (which wouldn't catch duplicate initialization).
        self.write(self.home / ".zprofile", """
autoload -Uz compinit
autoload +X compinit
functions[_real_compinit]=$functions[compinit]
compinit() { print call >> "$HOME/compinit-calls"; _real_compinit "$@"; }
""")
        result = self.run_zsh(
            'source ~/.zshrc; print -r -- "$_comps[dotfiles-probe]|${_comps[probe with spaces]}"', "-lic")
        self.assertEqual(result, "_dotfiles_probe|_dotfiles_alias")
        self.assertEqual((self.home / "compinit-calls").read_text().splitlines(), ["call"])

    def test_nvm_prefers_explicit_directory_over_selected_brew(self):
        prefix = self.fake_brew()
        self.write(prefix / "opt/nvm/nvm.sh", "export NVM_SELECTED=brew\n")
        custom = self.home / "custom nvm"
        self.write(custom / "nvm.sh", "export NVM_SELECTED=custom\n")
        self.assertEqual(self.run_zsh('print -r -- "$NVM_SELECTED"', extra={"NVM_DIR": str(custom)}), "custom")
        self.assertEqual(self.run_zsh('print -r -- "$NVM_SELECTED"'), "brew")

    def test_local_override_is_last(self):
        self.write(self.home / ".zshrc.local", "export EDITOR=private-editor\n")
        self.assertEqual(self.run_zsh('print -r -- "$EDITOR"'), "private-editor")

    def test_all_sources_have_valid_syntax(self):
        for file in (ROOT / "zsh").rglob("*"):
            if file.is_file() and (file.name in (".zshenv", ".zprofile", ".zshrc") or file.suffix == ".zsh"):
                result = subprocess.run([ZSH, "-n", str(file)], capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
