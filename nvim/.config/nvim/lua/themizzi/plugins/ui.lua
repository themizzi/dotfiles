return {
	{ "folke/which-key.nvim", opts = {} },
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("tokyonight")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			local hooks = require("ibl.hooks")
			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3b4261" })
				vim.api.nvim_set_hl(0, "IblScope", { fg = "#7aa2f7", bold = true })
			end)
			require("ibl").setup({
				indent = { char = "│", highlight = { "IblIndent" } },
				scope = { enabled = true, char = "│", highlight = { "IblScope" }, show_start = true, show_end = true },
			})
		end,
	},
}
