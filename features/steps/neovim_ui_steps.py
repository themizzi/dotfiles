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
    os.environ["HOME"] = env["HOME"]
    os.environ["XDG_CONFIG_HOME"] = env["XDG_CONFIG_HOME"]
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
