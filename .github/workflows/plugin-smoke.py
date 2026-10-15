"""Explicit network integration test; never imported by the regular test suite."""
import os
import json
from pathlib import Path
import signal
import subprocess
import sys
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from features.environment import make_nvim_env  # noqa: E402


def run_editor(arguments, env, timeout):
    process = subprocess.Popen(["nvim", "--headless", *arguments], env=env,
                               start_new_session=True)
    try:
        status = process.wait(timeout=timeout)
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        raise
    if status:
        raise subprocess.CalledProcessError(status, process.args)


def main():
    context = SimpleNamespace(repo_root=Path(__file__).resolve().parents[2])
    try:
        env = make_nvim_env(context)
        env.pop("DOTFILES_SKIP_PLUGIN_BOOTSTRAP", None)
        config = Path(env['XDG_CONFIG_HOME']) / 'nvim'
        run_editor(['-l', str(config / 'setup.lua')], env, 300)
        # Startup errors may leave nvim's exit status at zero; assert explicitly.
        probe = Path(env["HOME"]) / "probe.lua"
        probe.write_text('''
local ok, err = pcall(function()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(require("lazy"), "lazy.nvim failed to load")
  assert(require("fzf-lua"), "fzf-lua failed to load")
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    assert(vim.fn.isdirectory(plugin.dir) == 1, "missing plugin: " .. plugin.name)
  end
end)
if not ok then
  io.stderr:write(tostring(err) .. "\\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
''', encoding="utf-8")
        run_editor(['-c', f'lua dofile({json.dumps(str(probe), ensure_ascii=False)})'], env, 60)
    finally:
        temporary = getattr(context, "nvim_home_tmp", None)
        if temporary is not None:
            temporary.cleanup()


if __name__ == "__main__":
    main()
