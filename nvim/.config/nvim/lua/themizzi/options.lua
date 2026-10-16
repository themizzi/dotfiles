local M = {}

function M.setup()
	vim.g.mapleader = " "
	vim.opt.number = true
	vim.opt.hidden = true
	vim.opt.laststatus = 2
	vim.opt.cmdheight = 1
	vim.opt.tabstop = 2
	vim.opt.shiftwidth = 2
	vim.opt.expandtab = true
	vim.opt.ignorecase = true
	vim.opt.smartcase = true
	vim.g.netrw_banner = 0
	vim.g.netrw_liststyle = 3
	-- Leave provider selection to Neovim: system tools first, then native OSC52
	-- when the terminal advertises support. Do not force unnamedplus: Neovim
	-- intentionally disables auto-OSC52 when that option is set (slow reads).
	-- Use explicit "+y / "+p; never replace paste with local registers.
end

return M
