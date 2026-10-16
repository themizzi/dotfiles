"""Real headless Neovim tests: isolated state, no plugin/network dependency."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from scripts.test_support import prepare_nvim_home


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
            env = prepare_nvim_home(ROOT, home)
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
            env.update(DOTFILES_SKIP_PLUGIN_BOOTSTRAP="1" if skip else "0",
                       DOTFILES_NVIM_AI="1" if ai else "0")
            result = subprocess.run([NVIM, "--headless", "-c", f"lua dofile({str(script)!r})"],
                                    cwd=workspace, env=env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse((Path(env['XDG_DATA_HOME']) / "nvim/lazy").exists(), "Startup bootstrapped plugins")
            self.assertNotIn("Error detected", result.stderr)

    def test_offline_startup_without_skip_never_bootstraps(self):
        self.run_lua("""
assert(vim.g.mapleader == ' ' and vim.o.number and vim.o.hidden)
assert(vim.o.cmdheight == 1)
assert(vim.g.clipboard == nil, 'Must preserve native clipboard auto-detection')
assert(vim.o.clipboard == '', 'Do not suppress automatic OSC52 fallback')
assert(vim.fn.exists(':CodeCompanion') == 0)
assert(not package.loaded['codecompanion'])
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

    def test_full_mode_capabilities_are_locked_and_ai_is_disabled_by_default(self):
        self.run_lua("""
local all = {}
local function collect(specs)
  for _, spec in ipairs(specs) do
    assert(#spec.commit == 40)
    if not all[spec[1]] or spec.opts then all[spec[1]] = spec end
    if spec.dependencies then collect(spec.dependencies) end
  end
end
collect(require('themizzi.plugins').specs())
for _, repo in ipairs({
  'folke/todo-comments.nvim', 'andythigpen/nvim-coverage', 'windwp/nvim-autopairs',
  'folke/flash.nvim', 'lukas-reineke/indent-blankline.nvim', 'saghen/blink.cmp',
  'rafamadriz/friendly-snippets', 'nvim-treesitter/nvim-treesitter', 'sindrets/diffview.nvim',
}) do assert(all[repo], 'Missing capability: ' .. repo) end
assert(not all['olimorris/codecompanion.nvim'])
assert(not all['ravitemer/mcphub.nvim'])
assert(not all['MeanderingProgrammer/render-markdown.nvim'])
assert(not all['HakonHarnes/img-clip.nvim'])
assert(not package.loaded['themizzi.plugins.ai'])
assert(all['saghen/blink.cmp'].opts.fuzzy.implementation == 'lua')
local ts = all['nvim-treesitter/nvim-treesitter']
assert(ts.branch == 'master' and ts.build == nil and ts.lazy == false)
local opts = require('themizzi.treesitter').opts
assert(#opts.ensure_installed == 0 and opts.auto_install == false)
assert(opts.highlight.enable and opts.indent.enable)
for _, key in ipairs({'tn', 'tp', 'tl', 'tq', 'tf', 'ts', 'fe'}) do
  assert(vim.fn.maparg(' ' .. key, 'n') ~= '', 'Missing mapping: ' .. key)
end
""")

    def test_ai_opt_in_keeps_codecompanion_chat_inline_and_optional_support(self):
        self.run_lua("""
vim.env.DOTFILES_NVIM_AI_ENDPOINT = 'https://example.invalid/custom/chat/completions'
vim.env.DOTFILES_NVIM_AI_MODEL = 'test-model'
local all = {}
for _, spec in ipairs(require('themizzi.plugins').specs()) do all[spec[1]] = spec end
for _, repo in ipairs({'olimorris/codecompanion.nvim', 'ravitemer/mcphub.nvim',
  'MeanderingProgrammer/render-markdown.nvim', 'HakonHarnes/img-clip.nvim'}) do
  assert(all[repo] and #all[repo].commit == 40)
end
local opts = all['olimorris/codecompanion.nvim'].opts()
assert(opts.strategies.chat.adapter == 'lmstudio')
assert(opts.strategies.inline.adapter == 'lmstudio')
assert(opts.strategies.cmd.adapter == 'lmstudio')
package.loaded['codecompanion.adapters'] = {extend = function(base, adapter)
  assert(base == 'openai_compatible')
  return adapter
end}
local adapter = opts.adapters.http.lmstudio()
assert(adapter.url == vim.env.DOTFILES_NVIM_AI_ENDPOINT)
assert(adapter.schema.model.default == 'test-model')
assert(adapter.schema.model.choices[1] == 'test-model')
assert(all['ravitemer/mcphub.nvim'].build == nil)
assert(all['ravitemer/mcphub.nvim'].opts.use_bundled_binary == false)
-- Opt-in with no installed plugins still stays on the offline baseline.
assert(vim.fn.exists(':CodeCompanionChat') == 0)
""", ai=True)

    def test_original_todo_mappings_dispatch_and_keep_search_fallback(self):
        self.run_lua("""
local calls = {}
local function record(name) return function() table.insert(calls, name) end end
package.loaded['todo-comments'] = {jump_next = record('next'), jump_prev = record('prev')}
for _, name in ipairs({'TodoLocList', 'TodoQuickFix', 'TodoFzfLua'}) do
  vim.api.nvim_create_user_command(name, record(name), {})
end
for _, key in ipairs({'tn', 'tp', 'tl', 'tq', 'tf'}) do
  vim.fn.maparg(' ' .. key, 'n', false, true).callback()
end
assert(table.concat(calls, ',') == 'next,prev,TodoLocList,TodoQuickFix,TodoFzfLua')
vim.ui.input = function(opts, callback)
  assert(opts.default == [[\\vTODO|FIXME|HACK|NOTE]])
  callback(nil)
end
vim.fn.maparg(' ts', 'n', false, true).callback()
""")

    def test_all_original_language_servers_use_blink_capabilities_after_mason(self):
        self.run_lua("""
local expected = {'ts_ls', 'tailwindcss', 'lua_ls', 'rust_analyzer', 'pyright', 'gopls',
  'yamlls', 'jsonls', 'html', 'cssls', 'astro', 'emmet_ls', 'graphql', 'bashls', 'dockerls', 'clangd'}
local configured, enabled = {}, {}
package.loaded['mason'] = {has_setup = true}
package.loaded['blink.cmp'] = {get_lsp_capabilities = function() return {blink = true} end}
vim.fn.executable = function() return 1 end
vim.lsp.config = function(name, opts) configured[name] = opts end
vim.lsp.enable = function(name) enabled[name] = true end
for _, spec in ipairs(require('themizzi.plugins.lsp')) do
  if spec[1] == 'neovim/nvim-lspconfig' then spec.config() end
end
assert(vim.tbl_count(configured) == 16)
for _, server in ipairs(expected) do
  assert(enabled[server] and configured[server].capabilities.blink, server)
end
""")

    def test_offline_lsp_uses_native_completion(self):
        self.run_lua("""
local called = false
vim.lsp.get_client_by_id = function() return {id = 42, supports_method = function() return true end} end
vim.lsp.completion.enable = function(enabled, client, buffer, opts)
  called = enabled and client == 42 and opts.autotrigger
end
vim.api.nvim_exec_autocmds('LspAttach', {buffer = 0, data = {client_id = 42}})
assert(called)
called = false
package.loaded['blink.cmp'] = {}
vim.api.nvim_exec_autocmds('LspAttach', {buffer = 0, data = {client_id = 42}})
assert(not called, 'Native completion must not compete with Blink')
""")

    def test_plugin_specs_are_locked_and_formatters_are_alternatives(self):
        self.run_lua("""
local specs = require('themizzi.plugins').specs()
for _, spec in ipairs(specs) do assert(#spec.commit == 40) end
local editor = require('themizzi.plugins.editor')
local formats
for _, spec in ipairs(editor) do
  if spec[1] == 'stevearc/conform.nvim' then formats = spec.opts.formatters_by_ft end
end
assert(formats.python.stop_after_first)
assert(formats.javascript.stop_after_first)
""")


if __name__ == "__main__":
    unittest.main()
