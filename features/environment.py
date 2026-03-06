from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path


def _safe_close_nvim(context) -> None:
    nvim = getattr(context, "nvim", None)
    if nvim is None:
        return
    try:
        nvim.request("nvim_command", "qa!")
    except Exception:
        pass
    finally:
        context.nvim = None


def before_all(context):
    context.repo_root = Path(__file__).resolve().parents[1]
    context.fixture_workspace = context.repo_root / "test" / "fixtures" / "workspace"


def before_scenario(context, scenario):
    context.nvim = None
    context.nvim_home_tmp = None
    context.install_home_tmp = None
    context.zsh_home_tmp = None
    context.ui_state = None


def after_scenario(context, scenario):
    _safe_close_nvim(context)

    if context.nvim_home_tmp is not None:
        context.nvim_home_tmp.cleanup()
        context.nvim_home_tmp = None

    if context.install_home_tmp is not None:
        context.install_home_tmp.cleanup()
        context.install_home_tmp = None

    if context.zsh_home_tmp is not None:
        context.zsh_home_tmp.cleanup()
        context.zsh_home_tmp = None


def make_nvim_env(context) -> dict[str, str]:
    home_tmp = tempfile.TemporaryDirectory(prefix="dotfiles-nvim-home-")
    context.nvim_home_tmp = home_tmp
    home_dir = Path(home_tmp.name)

    vimrc_link = home_dir / ".vimrc"
    if vimrc_link.exists() or vimrc_link.is_symlink():
        vimrc_link.unlink()
    vimrc_link.symlink_to(context.repo_root / "vim" / ".vimrc")

    env = os.environ.copy()
    env["HOME"] = str(home_dir)
    env["XDG_CONFIG_HOME"] = str(context.repo_root / "nvim" / ".config")
    env["DOTFILES_SKIP_PLUGIN_BOOTSTRAP"] = "1"
    return env


def make_install_env(context) -> tuple[dict[str, str], Path]:
    install_tmp = tempfile.TemporaryDirectory(prefix="dotfiles-install-home-")
    context.install_home_tmp = install_tmp
    home_dir = Path(install_tmp.name)
    env = os.environ.copy()
    env["HOME"] = str(home_dir)
    return env, home_dir


def require_executable(name: str) -> str:
    resolved = shutil.which(name)
    if not resolved:
        raise AssertionError(f"Required executable not found in PATH: {name}")
    return resolved
