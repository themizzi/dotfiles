from __future__ import annotations

import re
import shutil
import subprocess
import uuid
from pathlib import Path

from behave import given, then, when


@then("zellij install targets should exist in the temporary HOME")
def step_zellij_targets_exist_in_tmp_home(context):
    config_path = context.install_home / ".config" / "zellij" / "config.kdl"
    layout_path = context.install_home / ".config" / "zellij" / "layouts" / "default.kdl"
    assert config_path.exists(), f"Expected install target to exist: {config_path}"
    assert layout_path.exists(), f"Expected install target to exist: {layout_path}"


@given("the repository zellij config")
def step_repo_zellij_config(context):
    config_path = context.repo_root / "zellij" / ".config" / "zellij" / "config.kdl"
    assert config_path.exists(), f"Missing zellij config: {config_path}"
    context.zellij_config_path = config_path
    context.zellij_config_text = config_path.read_text(encoding="utf-8")


@then("it should include the exact zellij command palette keybinding syntax")
def step_config_has_exact_palette_keybinding(context):
    expected = (
        'bind "Alt Space" { Run "sh" "-lc" '
        '"$HOME/.config/zellij/scripts/palette.sh" { floating true; close_on_exit true; }; }'
    )
    assert expected in context.zellij_config_text, (
        "Expected exact palette keybinding syntax in zellij config"
    )


@then("it should include bindings for pane split and pane focus movement")
def step_config_has_split_and_focus_bindings(context):
    text = context.zellij_config_text
    has_split = bool(re.search(r'NewPane\s+"([Rr]ight|[Dd]own)"', text))
    has_focus_move = "MoveFocus" in text
    assert has_split, 'Expected split binding (NewPane "Right" or NewPane "Down")'
    assert has_focus_move, "Expected MoveFocus binding"


@then("it should include a session workflow binding")
def step_config_has_session_binding(context):
    text = context.zellij_config_text
    has_session_binding = (
        'SwitchToMode "Session"' in text
        or 'SwitchToMode "session"' in text
    )
    assert has_session_binding, "Expected a session workflow binding"


@given("the repository zellij default layout")
def step_repo_zellij_layout(context):
    layout_path = context.repo_root / "zellij" / ".config" / "zellij" / "layouts" / "default.kdl"
    assert layout_path.exists(), f"Missing zellij layout: {layout_path}"
    context.zellij_layout_path = layout_path
    context.zellij_layout_text = layout_path.read_text(encoding="utf-8")


@then("it should define multiple panes")
def step_layout_has_multiple_panes(context):
    pane_count = len(re.findall(r"\bpane\b", context.zellij_layout_text))
    assert pane_count >= 2, f"Expected at least 2 panes, got {pane_count}"


@given("required runtime dependencies are installed")
def step_required_runtime_deps(context):
    if shutil.which("zellij") is None:
        context.scenario.skip("zellij is not installed in this environment")


@then('"{executable}" should be discoverable in PATH')
def step_executable_discoverable(context, executable):
    resolved = shutil.which(executable)
    assert resolved is not None, f"Expected {executable} in PATH"


@given("zellij is available for command execution")
def step_zellij_available_for_execution(context):
    if shutil.which("zellij") is None:
        context.scenario.skip("zellij is not installed in this environment")


@when("I run the zellij version command")
def step_run_zellij_version(context):
    context.zellij_version_result = subprocess.run(
        ["zellij", "--version"],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )


@when("I run a zellij session listing command")
def step_run_zellij_session_listing(context):
    session_name = f"behave-zellij-{uuid.uuid4().hex[:8]}"
    context.zellij_test_session = session_name
    context.zellij_create_session_result = subprocess.run(
        ["zellij", "attach", "-b", session_name],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )

    primary = subprocess.run(
        ["zellij", "list-sessions"],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    if primary.returncode == 0:
        context.zellij_sessions_result = primary
        return

    fallback = subprocess.run(
        ["zellij", "ls"],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    context.zellij_sessions_result = fallback


@then("the zellij version command should succeed")
def step_zellij_version_succeeds(context):
    result = context.zellij_version_result
    assert result.returncode == 0, (
        "zellij --version failed\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )


@then("the zellij session listing command should succeed")
def step_zellij_session_listing_succeeds(context):
    create_result = context.zellij_create_session_result
    result = context.zellij_sessions_result
    cleanup = subprocess.run(
        ["zellij", "kill-session", context.zellij_test_session],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    assert create_result.returncode == 0, (
        "zellij detached session creation failed\n"
        f"stdout:\n{create_result.stdout}\n"
        f"stderr:\n{create_result.stderr}\n"
    )
    assert result.returncode == 0, (
        "zellij session listing failed (list-sessions / ls)\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
    assert context.zellij_test_session in result.stdout, (
        "Created test session not present in list-sessions output\n"
        f"session: {context.zellij_test_session}\n"
        f"stdout:\n{result.stdout}\n"
    )
    assert cleanup.returncode == 0, (
        "zellij test session cleanup failed\n"
        f"stdout:\n{cleanup.stdout}\n"
        f"stderr:\n{cleanup.stderr}\n"
    )
