-- Explicit setup only: nvim --headless -l ~/.config/nvim/setup.lua
if vim.fn.has("nvim-0.12") == 0 then
	error("Neovim >= 0.12 is required")
end
if vim.env.DOTFILES_SKIP_PLUGIN_BOOTSTRAP == "1" then
	error("Unset DOTFILES_SKIP_PLUGIN_BOOTSTRAP for explicit plugin setup")
end
local manager = require("themizzi.lazy")
-- -l runs without normal init/plugin loading; lazy requires this flag.
vim.opt.loadplugins = true
local function git(args)
	local command = { "git" }
	vim.list_extend(command, args)
	local result = vim.system(command, { text = true }):wait()
	assert(result.code == 0, result.stderr)
end
if not vim.uv.fs_stat(manager.path) then
	git({ "clone", "--filter=blob:none", "--no-checkout", "https://github.com/folke/lazy.nvim.git", manager.path })
end
git({ "-C", manager.path, "checkout", "--detach", manager.commit })
if not package.loaded.lazy then
	manager.setup()
end
-- Specs pin the reviewed commits. Install missing plugins, then restore existing
-- ones, without sync's cleanup of other directories.
require("lazy").install({ wait = true })
require("lazy").restore({ wait = true })
for _, plugin in pairs(require("lazy.core.config").plugins) do
	assert(plugin._.installed, "Plugin installation failed: " .. plugin.name)
	for _, task in ipairs(plugin._.tasks or {}) do
		assert(not task:has_errors(), "Plugin setup failed: " .. plugin.name)
	end
end
if vim.env.DOTFILES_NVIM_INSTALL_PARSERS == "1" then
	-- Install the pinned plugin's parsers and queries using its synchronous task API.
	require("lazy").load({ plugins = { "nvim-treesitter" } })
	require("nvim-treesitter").install(require("themizzi.treesitter").parsers):wait(300000)
	for _, parser in ipairs(require("themizzi.treesitter").parsers) do
		assert(pcall(vim.treesitter.language.add, parser), "Parser installation failed: " .. parser)
	end
end
vim.cmd("qa!")
