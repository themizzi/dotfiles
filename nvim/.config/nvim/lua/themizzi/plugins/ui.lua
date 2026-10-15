return {
	{ "folke/which-key.nvim", opts = {} },
	{ "folke/tokyonight.nvim", priority = 1000, config = function() vim.cmd.colorscheme("tokyonight") end },
}
