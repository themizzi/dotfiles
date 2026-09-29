return {
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				git = {
					enable = true,
					ignore = false,
				},
				update_focused_file = {
					enable = true,
					update_root = false,
				},
				renderer = {
					highlight_git = true,
					icons = {
						show = {
							git = true,
						},
					},
				},
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local ok, fzf = pcall(require, "fzf-lua")
			if ok then
				fzf.setup({})
			end
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		config = function()
			local flash = require("flash")

			flash.setup({})

			vim.keymap.set({ "n", "x", "o" }, "s", flash.jump, { silent = true, desc = "Flash jump" })
			vim.keymap.set({ "n", "x", "o" }, "S", flash.treesitter, { silent = true, desc = "Flash treesitter" })
		end,
	},
}
