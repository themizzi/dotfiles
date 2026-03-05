from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

import pynvim
from behave import given, then, when

from features.environment import make_nvim_env, require_executable


@dataclass
class GridState:
    rows: dict[int, str] = field(default_factory=dict)
    width: int = 80

    def consume_redraw(self, redraw_batches):
        for event in redraw_batches:
            name = event[0]
            args = event[1:]

            if name == "grid_resize":
                for grid, width, _height in args:
                    if grid == 1:
                        self.width = width
            elif name == "grid_clear":
                for grid in args:
                    if grid == 1:
                        self.rows.clear()
            elif name == "grid_line":
                for grid, row, col_start, cells, _wrap in args:
                    if grid != 1:
                        continue
                    self._apply_line(row, col_start, cells)

    def _apply_line(self, row: int, col_start: int, cells):
        current = list(self.rows.get(row, " " * self.width).ljust(self.width))
        col = col_start
        for cell in cells:
            text = cell[0]
            repeat = cell[2] if len(cell) > 2 else 1
            for _ in range(repeat):
                for ch in text:
                    if col < len(current):
                        current[col] = ch
                    col += 1
        self.rows[row] = "".join(current).rstrip()

    def text(self) -> str:
        if not self.rows:
            return ""
        last_row = max(self.rows)
        return "\n".join(self.rows.get(i, "") for i in range(last_row + 1))


def _spawn_nvim(context, cwd: Path):
    require_executable("nvim")
    env = make_nvim_env(context)
    argv = ["nvim", "--embed"]

    original_home = os.environ.get("HOME")
    original_xdg = os.environ.get("XDG_CONFIG_HOME")
    original_skip_bootstrap = os.environ.get("DOTFILES_SKIP_PLUGIN_BOOTSTRAP")
    os.environ["HOME"] = env["HOME"]
    os.environ["XDG_CONFIG_HOME"] = env["XDG_CONFIG_HOME"]
    os.environ["DOTFILES_SKIP_PLUGIN_BOOTSTRAP"] = env["DOTFILES_SKIP_PLUGIN_BOOTSTRAP"]
    try:
        context.nvim = pynvim.attach("child", argv=argv)
    finally:
        if original_home is None:
            os.environ.pop("HOME", None)
        else:
            os.environ["HOME"] = original_home
        if original_xdg is None:
            os.environ.pop("XDG_CONFIG_HOME", None)
        else:
            os.environ["XDG_CONFIG_HOME"] = original_xdg
        if original_skip_bootstrap is None:
            os.environ.pop("DOTFILES_SKIP_PLUGIN_BOOTSTRAP", None)
        else:
            os.environ["DOTFILES_SKIP_PLUGIN_BOOTSTRAP"] = original_skip_bootstrap

    context.nvim.request("nvim_set_current_dir", str(cwd))
    context.nvim.request(
        "nvim_ui_attach",
        100,
        30,
        {"rgb": True, "ext_linegrid": True},
    )
    context.ui_state = GridState()
    _refresh_screen(context)


def _refresh_screen(context):
    context.nvim.request("nvim_command", "redraw!")
    for _ in range(50):
        message = context.nvim.next_message()
        if not message:
            continue
        kind, name, payload = message
        if kind == "notification" and name == "redraw":
            context.ui_state.consume_redraw(payload)
            return
    raise AssertionError("Unable to capture redraw notification after redraw!")


def _termcodes(context, keys: str) -> str:
    return context.nvim.request("nvim_replace_termcodes", keys, True, False, True)


@given("an embedded Neovim session")
def step_embedded_nvim(context):
    _spawn_nvim(context, context.repo_root)


@given("an embedded Neovim session in the fixture workspace")
def step_embedded_nvim_fixture_workspace(context):
    _spawn_nvim(context, context.fixture_workspace)


@given("the active buffer is not netrw")
def step_active_buffer_not_netrw(context):
    filetype = context.nvim.request("nvim_eval", "&filetype")
    assert filetype != "netrw", f"Expected non-netrw buffer, got filetype={filetype}"


@when('I send normal keys "{keys}"')
def step_send_normal_keys(context, keys):
    context.nvim.request("nvim_input", _termcodes(context, keys))
    _refresh_screen(context)


@given("fzf-lua picker calls are captured")
def step_capture_fzf_picker_calls(context):
    context.nvim.request(
        "nvim_exec_lua",
        """
        _G.dotfiles_picker_calls = {}
        local function record(name)
          return function()
            vim.g.dotfiles_last_picker = name
            table.insert(_G.dotfiles_picker_calls, name)
          end
        end
        package.loaded["fzf-lua"] = {
          files = record("files"),
          buffers = record("buffers"),
          commands = record("commands"),
          helptags = record("helptags"),
          live_grep = record("live_grep"),
          grep = record("grep"),
        }
        """,
        [],
    )


@given("multiple buffers are open")
def step_multiple_buffers_are_open(context):
    context.nvim.request("nvim_command", "edit alpha.txt")
    context.nvim.request("nvim_command", "edit beta.txt")


@given("ripgrep is installed")
def step_ripgrep_installed(context):
    context.nvim.request("nvim_set_var", "dotfiles_force_has_rg", 1)
    context.nvim.request("nvim_set_var", "dotfiles_force_no_rg", 0)


@given("ripgrep is not installed")
def step_ripgrep_not_installed(context):
    context.nvim.request("nvim_set_var", "dotfiles_force_has_rg", 0)
    context.nvim.request("nvim_set_var", "dotfiles_force_no_rg", 1)


@when('I move the netrw cursor to "{filename}"')
def step_move_netrw_cursor_to_filename(context, filename):
    context.nvim.request("nvim_call_function", "search", [filename, "w"])
    _refresh_screen(context)


@then("a netrw buffer should be visible")
def step_netrw_buffer_visible(context):
    screen = ""
    for _ in range(5):
        _refresh_screen(context)
        screen = context.ui_state.text()
        if "alpha.txt" in screen and "beta.txt" in screen:
            return
    raise AssertionError(screen)


@then("no netrw buffer should be visible")
def step_netrw_buffer_not_visible(context):
    screen = ""
    for _ in range(5):
        _refresh_screen(context)
        screen = context.ui_state.text()
        if "alpha.txt" not in screen and "beta.txt" not in screen:
            return
    raise AssertionError(screen)


@then('the current buffer path should end with "{suffix}"')
def step_buffer_path_endswith(context, suffix):
    buf_name = context.nvim.request("nvim_buf_get_name", 0)
    assert buf_name.endswith(suffix), f"Expected suffix {suffix}, got {buf_name}"


@then('the current buffer should contain line "{line}"')
def step_buffer_contains_line(context, line):
    lines = context.nvim.request("nvim_buf_get_lines", 0, 0, -1, False)
    assert line in lines, f"Expected line {line!r} in buffer lines {lines!r}"


@then("the fzf-lua files picker should be active")
def step_fzf_files_picker_active(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "files", f"Expected files picker, got {picker!r}"


@then("the fzf-lua buffers picker should be active")
def step_fzf_buffers_picker_active(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "buffers", f"Expected buffers picker, got {picker!r}"


@then("the fzf-lua commands picker should be active")
def step_fzf_commands_picker_active(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "commands", f"Expected commands picker, got {picker!r}"


@then("the fzf-lua helptags picker should be active")
def step_fzf_helptags_picker_active(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "helptags", f"Expected helptags picker, got {picker!r}"


@then("the fzf-lua live grep picker should be active")
def step_fzf_live_grep_picker_active(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "live_grep", f"Expected live_grep picker, got {picker!r}"


@then("Neovim should not error fatally")
def step_nvim_not_error_fatally(context):
    result = context.nvim.request("nvim_eval", "1 + 1")
    assert result == 2, f"Expected Neovim to stay responsive, got {result!r}"


@then("a configured fallback search behavior should be used")
def step_configured_fallback_behavior_used(context):
    picker = context.nvim.request("nvim_get_var", "dotfiles_last_picker")
    assert picker == "grep_fallback", f"Expected grep fallback, got {picker!r}"
