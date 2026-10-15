"""Real headless Neovim tests: isolated state, no plugin/network dependency."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


class NeovimTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not NVIM:
            raise unittest.SkipTest("Neovim is not installed")
        version = subprocess.run(
            [NVIM, "--headless", "-u", "NONE", "+lua print(vim.fn.has('nvim-0.11.3'))", "+qa!"],
            capture_output=True, text=True, check=True,
        )
        if version.stderr.strip() != "1":
            raise unittest.SkipTest("Neovim >= 0.11.3 is required")

    def run_lua(self, source, *, skip=True, ai=False):
        with tempfile.TemporaryDirectory(prefix="dotfiles-neovim-") as directory:
            home = Path(directory)
            config = home / "config" / "nvim"
            config.parent.mkdir()
            config.symlink_to(ROOT / "nvim" / ".config" / "nvim", target_is_directory=True)
            (home / ".vimrc").symlink_to(ROOT / "vim" / ".vimrc")
            workspace = home / "workspace"
            workspace.mkdir()
            (workspace / "alpha.txt").write_text("alpha fixture line\nsecond needle\n")
            (workspace / "beta.txt").write_text("beta fixture line\n")
            script = home / "test.lua"
            script.write_text(
                "local ok, err = xpcall(function()\n" + source
                + "\nend, debug.traceback)\n"
                + "if not ok then io.stderr:write(err); vim.cmd('cquit 1') end\nvim.cmd('qa!')\n"
            )
            env = {key: value for key, value in os.environ.items()
                   if not key.startswith(("XDG_", "DOTFILES_NVIM_", "NVIM"))}
            env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
                       XDG_DATA_HOME=str(home / "data"), XDG_STATE_HOME=str(home / "state"),
                       XDG_CACHE_HOME=str(home / "cache"),
                       DOTFILES_SKIP_PLUGIN_BOOTSTRAP="1" if skip else "0",
                       DOTFILES_NVIM_AI="1" if ai else "0")
            result = subprocess.run([NVIM, "--headless", "-c", f"lua dofile({str(script)!r})"],
                                    cwd=workspace, env=env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse((home / "data" / "nvim" / "lazy").exists(), "Startup bootstrapped plugins")
            self.assertNotIn("Error detected", result.stderr)

    def test_offline_startup_without_skip_never_bootstraps(self):
        self.run_lua("""
assert(vim.g.mapleader == ' ' and vim.o.number and vim.o.hidden)
assert(vim.o.cmdheight == 1)
assert(vim.g.clipboard == nil, 'Must preserve native clipboard auto-detection')
assert(vim.o.clipboard == '', 'Do not suppress automatic OSC52 fallback')
assert(vim.fn.exists(':DotfilesAI') == 0)
for _, lhs in ipairs({' ff', ' fb', ' fc', ' fg', ' fh', ' e'}) do
  assert(vim.fn.maparg(lhs, 'n') ~= '', 'Missing mapping: ' .. lhs)
end
""", skip=False)

    def test_netrw_toggle_and_open_file(self):
        self.run_lua("""
vim.cmd('edit alpha.txt')
local explorer = vim.fn.maparg(' e', 'n', false, true).callback
explorer()
assert(vim.bo.filetype == 'netrw')
explorer()
for _, win in ipairs(vim.api.nvim_list_wins()) do
  assert(vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'netrw')
end
explorer()
assert(vim.fn.search('alpha.txt', 'w') > 0)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'mx', false)
assert(vim.api.nvim_buf_get_name(0):match('alpha.txt$'))
assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'alpha fixture line')
""")

    def test_native_osc52_fallback_without_system_tools(self):
        self.run_lua("""
if vim.fn.has('mac') == 1 then return end -- macOS always prefers pbcopy.
vim.env.PATH = '/nonexistent'
vim.env.DISPLAY, vim.env.WAYLAND_DISPLAY, vim.env.TMUX = nil, nil, nil
vim.g.termfeatures = {osc52 = true}
assert(vim.fn['provider#clipboard#Executable']() == 'OSC 52')
assert(vim.g.clipboard == nil, 'Native provider must not be replaced')
""")

    def test_builtin_pickers_and_search(self):
        self.run_lua("""
local function invoke(lhs) vim.fn.maparg(lhs, 'n', false, true).callback() end
vim.ui.select = function(items, opts, callback)
  assert(#items > 0, opts.prompt)
  callback(items[1])
end
invoke(' ff')
assert(vim.api.nvim_buf_get_name(0):match('alpha.txt$'))
invoke(' fb')
invoke(' fh')
assert(vim.bo.filetype == 'help')
vim.ui.select = function(items, opts, callback)
  assert(#items > 0 and opts.prompt:match('Commands'))
  callback(nil)
end
invoke(' fc')
vim.g.dotfiles_force_no_rg = 1
vim.ui.input = function(_, callback) callback('needle') end
invoke(' fg')
assert(vim.g.dotfiles_last_picker == 'grep_fallback')
local entries = vim.fn.getqflist()
assert(#entries == 1 and entries[1].lnum == 2)
vim.ui.input = function(_, callback) callback(nil) end
invoke(' fg')
assert(#vim.fn.getqflist() == 1, 'Cancel changed search results')
""")

    def test_fzf_dispatch(self):
        self.run_lua("""
vim.g.dotfiles_capture_pickers = 1
vim.g.dotfiles_force_has_rg = 1
local calls = {}
package.loaded['fzf-lua'] = {}
for _, name in ipairs({'files', 'buffers', 'commands', 'live_grep', 'helptags'}) do
  package.loaded['fzf-lua'][name] = function() table.insert(calls, name) end
end
for _, key in ipairs({'ff', 'fb', 'fc', 'fg', 'fh'}) do
  vim.fn.maparg(' ' .. key, 'n', false, true).callback()
end
assert(table.concat(calls, ',') == 'files,buffers,commands,live_grep,helptags')
""")

    def test_ai_is_explicit_opt_in(self):
        self.run_lua("assert(vim.fn.exists(':DotfilesAI') == 2)", ai=True)

    @unittest.skipUnless(shutil.which("curl"), "curl is required for the opt-in AI command")
    def test_ai_sends_only_explicit_prompt_and_handles_response(self):
        self.run_lua("""
vim.env.DOTFILES_NVIM_AI_ENDPOINT = 'http://127.0.0.1:1234/v1/chat/completions'
vim.env.DOTFILES_NVIM_AI_MODEL = 'test-model'
vim.env.DOTFILES_NVIM_AI_API_KEY = 'secret-test-token'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'PRIVATE BUFFER CONTENT'})
local called = false
vim.system = function(argv, opts, callback)
  called = true
  assert(argv[#argv] == vim.env.DOTFILES_NVIM_AI_ENDPOINT)
  assert(not table.concat(argv, ' '):match('secret%-test%-token'))
  assert(opts.stdin:match('Authorization: Bearer secret%-test%-token'))
  local file = argv[#argv - 1]:sub(2)
  local body = vim.json.decode(table.concat(vim.fn.readfile(file), '\\n'))
  assert(body.messages[1].content == 'explain closures')
  assert(#body.messages == 1)
  callback({code = 0, stdout = vim.json.encode({choices = {{message = {content = 'A closure captures scope.'}}}})})
end
vim.cmd('DotfilesAI explain closures')
assert(called)
vim.wait(1000, function() return vim.bo.buftype == 'nofile' end)
assert(vim.bo.buftype == 'nofile')
assert(vim.api.nvim_get_current_line() == 'A closure captures scope.')
""", ai=True)

    def test_plugin_specs_are_locked_and_formatters_are_alternatives(self):
        self.run_lua("""
local specs = require('themizzi.plugins').specs()
for _, spec in ipairs(specs) do assert(#spec.commit == 40) end
local editor = require('themizzi.plugins.editor')
local formats = editor[3].opts.formatters_by_ft
assert(formats.python.stop_after_first)
assert(formats.javascript.stop_after_first)
""")


if __name__ == "__main__":
    unittest.main()
