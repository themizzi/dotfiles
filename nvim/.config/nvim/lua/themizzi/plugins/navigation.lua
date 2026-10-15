return {
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			disable_netrw = false, hijack_netrw = false,
			git = { enable = true }, filters = { git_ignored = false },
			update_focused_file = { enable = true, update_root = { enable = false } },
			renderer = { highlight_git = "all", icons = { show = { git = true } } },
		},
	},
	{ "ibhagwan/fzf-lua", opts = {}, dependencies = { "nvim-tree/nvim-web-devicons" } },
	{
		"folke/flash.nvim",
		opts = {},
		keys = {
			{ "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
			{ "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
		},
	},
}
