"""Standard-library helpers for private, subprocess-only editor tests."""
import os
from pathlib import Path
import shutil


STARTUP_OVERRIDES = {
    'ENV', 'BASH_ENV', 'ZDOTDIR', 'VIMINIT', 'EXINIT', 'GVIMINIT', 'MYVIMRC',
    'MYGVIMRC', 'VIM', 'VIMRUNTIME', 'LUA_PATH', 'LUA_CPATH', 'HISTFILE',
    'STARSHIP_CONFIG', 'STARSHIP_CACHE', 'RIPGREP_CONFIG_PATH',
    'GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_INDEX_FILE',
    'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_CEILING_DIRECTORIES', 'GIT_DISCOVERY_ACROSS_FILESYSTEM',
}


def isolated_env(home: Path) -> dict[str, str]:
    """Return a private environment without mutating the caller's os.environ."""
    env = {name: value for name, value in os.environ.items()
           if name not in STARTUP_OVERRIDES
           and not name.startswith(('XDG_', 'NVIM', 'DOTFILES_NVIM_', 'GIT_CONFIG_'))}
    env['HOME'] = str(home)
    for name, relative in {
        'XDG_CONFIG_HOME': '.config', 'XDG_DATA_HOME': '.local/share',
        'XDG_STATE_HOME': '.local/state', 'XDG_CACHE_HOME': '.cache',
        'XDG_RUNTIME_DIR': '.runtime', 'XDG_CONFIG_DIRS': '.config-dirs',
        'XDG_DATA_DIRS': '.data-dirs', 'TMPDIR': '.tmp', 'TMP': '.tmp', 'TEMP': '.tmp',
    }.items():
        directory = home / relative
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        env[name] = str(directory)
    env['DOTFILES_SKIP_PLUGIN_BOOTSTRAP'] = '1'
    env['GIT_CONFIG_GLOBAL'] = str(home / '.gitconfig')
    env['GIT_CONFIG_NOSYSTEM'] = '1'
    return env


def prepare_nvim_home(repo_root: Path, home: Path) -> dict[str, str]:
    """Copy config into a caller-owned temporary HOME; do not launch any process."""
    env = isolated_env(home)
    shutil.copy2(repo_root / 'vim/.vimrc', home / '.vimrc')
    shutil.copytree(repo_root / 'nvim/.config/nvim', Path(env['XDG_CONFIG_HOME']) / 'nvim')
    return env
