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
