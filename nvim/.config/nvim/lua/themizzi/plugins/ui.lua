return {
	{ "folke/which-key.nvim", opts = {} },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({ flavour = "mocha" })
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = { theme = "catppuccin-mocha" },
			sections = {
				lualine_x = {
					function()
						local status = package.loaded["opencode.events.status"]
						return status and status.statusline() or ""
					end,
					"encoding",
					"fileformat",
					"filetype",
				},
			},
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {
			heading = { width = "block", left_pad = 1, right_pad = 1 },
			code = { width = "full", left_pad = 1, language = true },
			checkbox = {
				unchecked = { icon = "󰄱 " },
				checked = { icon = "󰱒 " },
			},
		},
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
