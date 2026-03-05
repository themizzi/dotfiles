from __future__ import annotations

import re
import os
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path

from behave import given, then, when


PALETTE_SCRIPT_RELATIVE_PATH = (
    "zellij/.config/zellij/scripts/palette.sh"
)


def _write_palette_test_config(home_dir: Path) -> None:
    config_dir = home_dir / ".config" / "zellij"
    config_dir.mkdir(parents=True, exist_ok=True)
    config_dir.joinpath("config.kdl").write_text(
        """
keybinds clear-defaults=true {
    normal {
        bind "Alt h" { NewPane "down"; }
    }
    tab {
        bind "down" { GoToNextTab; }
    }
    shared_except "locked" "tab" {
        bind "Ctrl t" { SwitchToMode "tab"; }
    }
}
""".strip()
        + "\n",
        encoding="utf-8",
    )


def _rendered_hints_by_action(render_stdout: str) -> dict[str, str]:
    hints: dict[str, str] = {}
    for line in render_stdout.splitlines():
        if "\t" not in line:
            continue
        label, hint_field = line.split("\t", 1)
        if not label.startswith("Action: "):
            continue
        hints[label.removeprefix("Action: ")] = hint_field.strip()
    return hints


def _palette_env_with_test_home(context, env: dict[str, str]) -> dict[str, str]:
    scoped = dict(env)
    if hasattr(context, "palette_test_home"):
        scoped["HOME"] = str(context.palette_test_home)
    return scoped


def _expand_tabs_for_width(line: str, tabstop: int = 8) -> str:
    expanded: list[str] = []
    col = 0
    for ch in line:
        if ch == "\t":
            spaces = tabstop - (col % tabstop)
            expanded.append(" " * spaces)
            col += spaces
            continue
        expanded.append(ch)
        col += 1
    return "".join(expanded)


def _assert_visual_width(line: str, width: int) -> str:
    rendered = _expand_tabs_for_width(line)
    assert len(rendered) == width, (
        "Expected deterministic row width\n"
        f"line: {line!r}\n"
        f"rendered: {rendered!r}\n"
        f"rendered_length: {len(rendered)}\n"
    )
    return rendered


def _assert_hinted_lines_right_aligned(render_result, width: int) -> None:
    assert render_result.returncode == 0, (
        "List-only render failed\n"
        f"stdout:\n{render_result.stdout}\n"
        f"stderr:\n{render_result.stderr}\n"
    )
    hinted_lines = [line for line in render_result.stdout.splitlines() if "\t" in line]
    assert hinted_lines, "Expected at least one hinted action line"
    for line in hinted_lines:
        label, hint_field = line.split("\t", 1)
        assert label.startswith("Action: "), f"Unexpected label field: {label!r}"
        assert hint_field.strip() != "", f"Expected hint text in line: {line!r}"
        _assert_visual_width(line, width)


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


@given("the repository zellij palette script")
def step_repo_zellij_palette_script(context):
    script_path = context.repo_root / PALETTE_SCRIPT_RELATIVE_PATH
    assert script_path.exists(), f"Missing zellij palette script: {script_path}"
    context.zellij_palette_script_path = script_path
    context.zellij_palette_script_text = script_path.read_text(encoding="utf-8")


@given("zellij and fzf are available for command execution")
def step_zellij_and_fzf_available_for_execution(context):
    if shutil.which("zellij") is None:
        context.scenario.skip("zellij is not installed in this environment")
    if shutil.which("fzf") is None:
        context.scenario.skip("fzf is not installed in this environment")
    script_path = context.repo_root / PALETTE_SCRIPT_RELATIVE_PATH
    assert script_path.exists(), f"Missing zellij palette script: {script_path}"
    context.zellij_palette_script_path = script_path


@given("deterministic palette bindings are configured")
def step_deterministic_palette_bindings_configured(context):
    tmp_home = tempfile.TemporaryDirectory(prefix="behave-palette-home-")
    context.palette_tmp_home = tmp_home
    home_path = Path(tmp_home.name)
    _write_palette_test_config(home_path)
    context.palette_test_home = home_path


@when('I run the zellij palette script with builder choice "{choice}" and dry-run mode')
def step_run_palette_with_builder_choice_dry_run(context, choice):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_CHOICE"] = choice
    env["DOTFILES_ZELLIJ_PALETTE_DRY_RUN"] = "1"
    env["DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE"] = "Run command"
    context.palette_script_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@then('the discovered action list should include "{action_label}"')
def step_discovered_action_list_should_include(context, action_label):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_LIST_ONLY"] = "1"
    result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, (
        "palette list-only mode failed\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
    labels = [line.split("\t", 1)[0].strip() for line in result.stdout.splitlines() if line.strip()]
    assert action_label in labels, (
        "Expected action label in discovered list\n"
        f"label: {action_label!r}\n"
        f"labels: {labels!r}\n"
    )


@then('it should print "{expected_output}"')
def step_palette_stdout_matches(context, expected_output):
    result = context.palette_script_result
    assert result.returncode == 0, (
        "Palette script exited non-zero\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
    assert result.stdout == f"{expected_output}\n", (
        "Palette script stdout mismatch\n"
        f"expected: {expected_output!r}\n"
        f"actual: {result.stdout!r}\n"
    )


@when('I run builder dry-run for action "{action}" with menu sequence')
def step_run_builder_dry_run_with_menu_sequence(context, action):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_CHOICE"] = f"Action: {action}"
    env["DOTFILES_ZELLIJ_PALETTE_DRY_RUN"] = "1"
    menu_items = [row["item"] for row in context.table]
    env["DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE"] = "\n".join(menu_items)
    context.palette_builder_env = env


@when("with input sequence")
def step_with_input_sequence(context):
    env = dict(getattr(context, "palette_builder_env", dict(os.environ)))
    input_values = [row["value"] for row in context.table]
    env["DOTFILES_ZELLIJ_PALETTE_INPUT_SEQUENCE"] = "\n".join(input_values)
    context.palette_script_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@when("I execute the prepared builder sequence")
def step_execute_prepared_builder_sequence(context):
    env = dict(getattr(context, "palette_builder_env", dict(os.environ)))
    context.palette_script_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@when('I run builder live execution for action "{action}" with menu sequence')
def step_run_builder_live_execution_with_menu_sequence(context, action):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_CHOICE"] = f"Action: {action}"
    menu_items = [row["item"] for row in context.table]
    env["DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE"] = "\n".join(menu_items)
    context.palette_script_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@then("it should include multiple argument values")
def step_should_include_multiple_argument_values(context):
    result = context.palette_script_result
    assert "echo hello" in result.stdout, (
        "Expected multiple argument values in rendered command\n"
        f"stdout: {result.stdout!r}\n"
    )


@then("options should render before positional args")
def step_options_should_render_before_positional_args(context):
    rendered = context.palette_script_result.stdout.strip()
    assert rendered.endswith("-f echo"), (
        "Expected options before positional arguments\n"
        f"rendered: {rendered!r}\n"
    )


@then("duplicate non-repeatable option handling should support keep and replace")
def step_duplicate_non_repeatable_keep_replace(context):
    def run_builder(menu_items, input_values):
        env = dict(os.environ)
        env["DOTFILES_ZELLIJ_PALETTE_CHOICE"] = "Action: new-pane"
        env["DOTFILES_ZELLIJ_PALETTE_DRY_RUN"] = "1"
        env["DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE"] = "\n".join(menu_items)
        env["DOTFILES_ZELLIJ_PALETTE_INPUT_SEQUENCE"] = "\n".join(input_values)
        return subprocess.run(
            [str(context.zellij_palette_script_path)],
            cwd=context.repo_root,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    keep_result = run_builder(
        [
            "Add option",
            "-n, --name <NAME>",
            "Add option",
            "-n, --name <NAME>",
            "Keep existing option",
            "Run command",
        ],
        ["pane1", "pane2"],
    )
    assert keep_result.returncode == 0, (
        "Keep-path run failed\n"
        f"stdout:\n{keep_result.stdout}\n"
        f"stderr:\n{keep_result.stderr}\n"
    )
    assert keep_result.stdout.strip() == "zellij action new-pane -n pane1", (
        "Expected duplicate keep flow to preserve first value\n"
        f"stdout: {keep_result.stdout!r}\n"
    )

    replace_result = run_builder(
        [
            "Add option",
            "-n, --name <NAME>",
            "Add option",
            "-n, --name <NAME>",
            "Replace existing option",
            "Run command",
        ],
        ["pane1", "pane2"],
    )
    assert replace_result.returncode == 0, (
        "Replace-path run failed\n"
        f"stdout:\n{replace_result.stdout}\n"
        f"stderr:\n{replace_result.stderr}\n"
    )
    assert replace_result.stdout.strip() == "zellij action new-pane -n pane2", (
        "Expected duplicate replace flow to use latest value\n"
        f"stdout: {replace_result.stdout!r}\n"
    )


@then("enum value selection path should be used")
def step_enum_value_selection_path_used(context):
    assert "switch-mode session" in context.palette_script_result.stdout, (
        "Expected enum selection to be rendered in command\n"
        f"stdout: {context.palette_script_result.stdout!r}\n"
    )


@then("free-text value entry path should be used")
def step_free_text_value_entry_used(context):
    assert "-n named-pane" in context.palette_script_result.stdout, (
        "Expected free-text value in rendered command\n"
        f"stdout: {context.palette_script_result.stdout!r}\n"
    )


@given("a temporary zellij session exists for command execution")
def step_temp_zellij_session_exists(context):
    session_name = f"behave-palette-{uuid.uuid4().hex[:8]}"
    context.palette_session_name = session_name
    context.palette_session_create_result = subprocess.run(
        ["zellij", "attach", "-b", session_name],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )


@then("the palette script command should succeed")
def step_palette_script_command_succeeds(context):
    create = context.palette_session_create_result
    result = context.palette_script_result
    assert create.returncode == 0, (
        "Temporary zellij session creation failed\n"
        f"stdout:\n{create.stdout}\n"
        f"stderr:\n{create.stderr}\n"
    )
    assert result.returncode == 0, (
        "Palette script command failed\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )


@then("temporary zellij session cleanup should succeed")
def step_temp_zellij_session_cleanup_succeeds(context):
    cleanup = subprocess.run(
        ["zellij", "kill-session", context.palette_session_name],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    assert cleanup.returncode == 0, (
        "Temporary zellij session cleanup failed\n"
        f"stdout:\n{cleanup.stdout}\n"
        f"stderr:\n{cleanup.stderr}\n"
    )


@then("old typed wording should not appear in palette script")
def step_old_typed_wording_should_not_appear(context):
    text = context.zellij_palette_script_text
    assert "Use typed options" not in text
    assert "typed value" not in text


@when("I list rendered palette lines with width 60")
def step_list_rendered_palette_lines_width_60(context):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_LIST_ONLY"] = "1"
    env["DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH"] = "60"
    env = _palette_env_with_test_home(context, env)
    result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    context.palette_render_result = result


@when("I list rendered palette lines with detected columns 60")
def step_list_rendered_palette_lines_detected_columns_60(context):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_LIST_ONLY"] = "1"
    env.pop("DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH", None)
    env["COLUMNS"] = "60"
    env = _palette_env_with_test_home(context, env)
    result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    context.palette_render_result = result


@when("I list rendered palette lines in pseudo-tty with stty columns 60 and env columns 40")
def step_list_rendered_palette_lines_pseudo_tty_stty_60_env_40(context):
    script_path = str(context.zellij_palette_script_path)
    command = (
        "stty cols 60; "
        "export DOTFILES_ZELLIJ_PALETTE_LIST_ONLY=1; "
        "unset DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH; "
        "export COLUMNS=40; "
        f"'{script_path}'"
    )
    if hasattr(context, "palette_test_home"):
        home_value = str(context.palette_test_home)
        command = f"export HOME='{home_value}'; " + command
    result = subprocess.run(
        ["script", "-q", "/dev/null", "sh", "-lc", command],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    context.palette_render_result = result


@then("rendered shortcut hints should be right-aligned")
def step_rendered_shortcut_hints_right_aligned(context):
    _assert_hinted_lines_right_aligned(context.palette_render_result, 60)


@then('rendered shortcut hints should be right-aligned to inner width {width:d}')
def step_rendered_shortcut_hints_right_aligned_inner_width(context, width):
    _assert_hinted_lines_right_aligned(context.palette_render_result, width)


@then('action "{action}" should show shortcut hint "{expected_hint}"')
def step_action_should_show_shortcut_hint(context, action, expected_hint):
    hints = _rendered_hints_by_action(context.palette_render_result.stdout)
    assert action in hints, f"Did not find hinted action line for: {action!r}"
    assert hints[action] == expected_hint, (
        "Expected exact inferred shortcut hint\n"
        f"action: {action!r}\n"
        f"expected_hint: {expected_hint!r}\n"
        f"actual_hint: {hints[action]!r}\n"
    )


@then('action "{action}" should show no shortcut hint')
def step_action_should_show_no_shortcut_hint(context, action):
    lines = context.palette_render_result.stdout.splitlines()
    matching = [line for line in lines if line.startswith(f"Action: {action}")]
    hints = _rendered_hints_by_action(context.palette_render_result.stdout)
    assert matching, f"Expected action line in rendered output: {action!r}"
    assert action not in hints and all("\t" not in line for line in matching), (
        "Expected action to render without shortcut hint\n"
        f"action: {action!r}\n"
        f"lines: {matching!r}\n"
    )


@then("hinted selection lines should keep action identity")
def step_hinted_selection_lines_keep_action_identity(context):
    env = dict(os.environ)
    env["DOTFILES_ZELLIJ_PALETTE_LIST_ONLY"] = "1"
    env["DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH"] = "60"
    env = _palette_env_with_test_home(context, env)
    list_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert list_result.returncode == 0, (
        "List-only render failed for selection identity check\n"
        f"stdout:\n{list_result.stdout}\n"
        f"stderr:\n{list_result.stderr}\n"
    )

    hinted_line = ""
    for line in list_result.stdout.splitlines():
        if line.startswith("Action: new-pane\t"):
            hinted_line = line
            break
    assert hinted_line != "", "Expected hinted new-pane line in rendered output"

    run_env = dict(os.environ)
    run_env["DOTFILES_ZELLIJ_PALETTE_CHOICE"] = hinted_line
    run_env["DOTFILES_ZELLIJ_PALETTE_DRY_RUN"] = "1"
    run_env["DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE"] = "Run command"
    run_env = _palette_env_with_test_home(context, run_env)
    run_result = subprocess.run(
        [str(context.zellij_palette_script_path)],
        cwd=context.repo_root,
        env=run_env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert run_result.returncode == 0, (
        "Hinted selection run failed\n"
        f"stdout:\n{run_result.stdout}\n"
        f"stderr:\n{run_result.stderr}\n"
    )
    assert run_result.stdout.strip() == "zellij action new-pane", (
        "Expected hint rendering to preserve action identity\n"
        f"choice: {hinted_line!r}\n"
        f"stdout: {run_result.stdout!r}\n"
    )


@then("hinted rows should follow action spacer shortcut columns")
def step_hinted_rows_follow_action_spacer_shortcut_columns(context):
    result = context.palette_render_result
    assert result.returncode == 0, (
        "List-only render failed for column layout check\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
    hinted_lines = [line for line in result.stdout.splitlines() if "\t" in line]
    assert hinted_lines, "Expected at least one hinted line"

    for line in hinted_lines:
        label, hint_field = line.split("\t", 1)
        rendered = _assert_visual_width(line, 60)
        shortcut = hint_field.strip()
        assert label.startswith("Action: "), f"Expected action label: {label!r}"
        assert shortcut != "", f"Expected shortcut text: {line!r}"
        shortcut_start = rendered.rfind(shortcut)
        assert shortcut_start > len(label), (
            "Expected spacer between action and shortcut\n"
            f"line: {line!r}\n"
            f"rendered: {rendered!r}\n"
        )
        spacer = rendered[len(label):shortcut_start]
        assert spacer.strip() == "", (
            "Expected only spacer characters between action and shortcut\n"
            f"line: {line!r}\n"
            f"rendered: {rendered!r}\n"
            f"spacer: {spacer!r}\n"
        )


@when('I inspect built-in palette options for command "{command}"')
def step_inspect_builtin_palette_options_for_command(context, command):
    context.palette_builtin_help_result = subprocess.run(
        ["zellij", "action", command, "--help"],
        cwd=context.repo_root,
        capture_output=True,
        text=True,
        check=False,
    )


@then('it should include option token "{token}"')
def step_palette_help_should_include_option_token(context, token):
    result = context.palette_builtin_help_result
    assert result.returncode == 0, (
        "zellij action help command failed\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}\n"
    )
    output = f"{result.stdout}\n{result.stderr}"
    assert re.search(rf"(^|[\s,]){re.escape(token)}([\s,]|$)", output) is not None, (
        "Expected option token in command help output\n"
        f"token: {token!r}\n"
        f"output:\n{output}\n"
    )


@when('I inspect discovered option tokens for action "{command}"')
def step_inspect_discovered_option_tokens_for_action(context, command):
    step_inspect_builtin_palette_options_for_command(context, command)


@then('it should include discovered option token "{token}"')
def step_should_include_discovered_option_token(context, token):
    step_palette_help_should_include_option_token(context, token)
