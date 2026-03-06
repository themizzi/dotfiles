from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

from behave import given, then, when


def _ensure_zsh_test_home(context) -> Path:
    if hasattr(context, "zsh_test_home"):
        return context.zsh_test_home

    tmp = tempfile.TemporaryDirectory(prefix="dotfiles-zsh-home-")
    context.zsh_home_tmp = tmp
    home = Path(tmp.name)
    context.zsh_test_home = home

    zshrc_src = context.repo_root / "zsh" / ".zshrc"
    plugins_src = context.repo_root / "zsh" / ".zsh_plugins.txt"
    (home / ".zshrc").write_text(zshrc_src.read_text(encoding="utf-8"), encoding="utf-8")
    (home / ".zsh_plugins.txt").write_text(
        plugins_src.read_text(encoding="utf-8"),
        encoding="utf-8",
    )
    return home


def _write_fake_antidote(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        """
antidote() {
  if [ "$1" = "load" ]; then
    _zsh_highlight() { :; }
  fi
}
""".lstrip(),
        encoding="utf-8",
    )


def _zsh_runtime_env(context) -> dict[str, str]:
    env = os.environ.copy()
    env["HOME"] = str(_ensure_zsh_test_home(context))
    env["DOTFILES_ANTIDOTE_HOMEBREW_PATH"] = str(getattr(context, "hb_antidote_path", ""))
    return env


def _run_zsh_probe(context, command: str):
    return subprocess.run(
        ["zsh", "-df", "-ic", command],
        cwd=context.repo_root,
        env=_zsh_runtime_env(context),
        capture_output=True,
        text=True,
        check=False,
    )


@given("~/.antidote/antidote.zsh does not exist")
def step_fallback_antidote_absent(context):
    home = _ensure_zsh_test_home(context)
    fallback = home / ".antidote" / "antidote.zsh"
    if fallback.exists():
        fallback.unlink()


@given("/opt/homebrew/opt/antidote/share/antidote/antidote.zsh exists")
def step_homebrew_antidote_exists(context):
    home = _ensure_zsh_test_home(context)
    hb_path = home / "test-homebrew" / "antidote.zsh"
    _write_fake_antidote(hb_path)
    context.hb_antidote_path = hb_path


@given("/opt/homebrew/opt/antidote/share/antidote/antidote.zsh does not exist")
def step_homebrew_antidote_absent(context):
    context.hb_antidote_path = Path("/tmp/does-not-exist-antidote.zsh")


@given("~/.antidote/antidote.zsh exists")
def step_fallback_antidote_exists(context):
    home = _ensure_zsh_test_home(context)
    _write_fake_antidote(home / ".antidote" / "antidote.zsh")


@when("I start an interactive zsh session")
def step_start_interactive_zsh(context):
    context.zsh_check_result = _run_zsh_probe(
        context,
        "source ~/.zshrc >/dev/null 2>&1; whence -w _zsh_highlight; "
        "typeset -f _zsh_highlight >/dev/null && echo OK",
    )


@then('"_zsh_highlight" should be a defined function')
def step_zsh_highlight_defined(context):
    result = context.zsh_check_result
    output = f"{result.stdout}\n{result.stderr}"
    assert "_zsh_highlight: function" in output or "OK" in output, (
        "Expected _zsh_highlight to be defined\n"
        f"returncode: {result.returncode}\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )


@given("the zsh plugin list file exists")
def step_plugins_file_exists(context):
    plugins = context.repo_root / "zsh" / ".zsh_plugins.txt"
    assert plugins.exists(), f"Missing plugins file: {plugins}"
    context.zsh_plugins_file = plugins


@then('"zsh-users/zsh-syntax-highlighting" should be the last non-empty entry')
def step_syntax_highlighting_is_last(context):
    lines = context.zsh_plugins_file.read_text(encoding="utf-8").splitlines()
    non_empty = [line.strip() for line in lines if line.strip()]
    assert non_empty, "Expected plugin list to include at least one plugin"
    assert non_empty[-1] == "zsh-users/zsh-syntax-highlighting", (
        "Expected syntax-highlighting plugin to be last non-empty entry\n"
        f"last: {non_empty[-1]!r}"
    )


@given("~/.zshrc.zwc exists")
def step_zshrc_zwc_exists(context):
    home = _ensure_zsh_test_home(context)
    (home / ".zshrc.zwc").write_text("stale-compiled-zshrc", encoding="utf-8")
    hb_path = home / "test-homebrew" / "antidote.zsh"
    _write_fake_antidote(hb_path)
    context.hb_antidote_path = hb_path


@when("I refresh shell configuration")
def step_refresh_shell_configuration(context):
    context.zsh_refresh_result = _run_zsh_probe(
        context,
        "rm -f ~/.zshrc.zwc; source ~/.zshrc >/dev/null 2>&1; "
        "typeset -f _zsh_highlight >/dev/null && echo OK",
    )


@then("runtime should reflect updated .zshrc plugin-loading logic")
def step_runtime_reflects_updated_logic(context):
    result = context.zsh_refresh_result
    assert "OK" in result.stdout, (
        "Expected refreshed runtime to load updated .zshrc logic\n"
        f"returncode: {result.returncode}\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
