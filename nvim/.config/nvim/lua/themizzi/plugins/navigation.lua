return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			dashboard = require("themizzi.dashboard").config(),
			input = { enabled = true },
			explorer = { enabled = true, replace_netrw = false },
			zen = { enabled = true, win = { width = 100 }, toggles = { dim = false } },
			picker = {
				enabled = true,
				sources = {
					explorer = {
						hidden = true,
						win = {
							list = {
								keys = {
									["a"] = { "explorer_add", desc = "Create file or directory" },
									["r"] = { "explorer_rename", desc = "Rename" },
									["d"] = { "explorer_del", desc = "Delete" },
									["c"] = { "explorer_copy", desc = "Copy" },
									["m"] = { "explorer_move", desc = "Move" },
									["H"] = { "toggle_hidden", desc = "Toggle hidden files" },
								},
							},
						},
					},
				},
				win = { input = { keys = { ["<a-o>"] = { "opencode_send", mode = { "n", "i" } } } } },
				actions = {
					opencode_send = function(picker)
						local items = vim.tbl_map(function(item)
							return item.file
									and require("opencode").format({
										path = item.file,
										from = item.pos,
										to = item.end_pos,
									})
								or item.text
						end, picker:selected({ fallback = true }))
						picker:close()
						require("opencode").prompt(table.concat(items, ", ") .. " ")
					end,
				},
			},
		},
	},
	{
		"stevearc/aerial.nvim",
		opts = { show_guides = true },
		keys = {
			{ "<leader>uo", "<cmd>AerialToggle!<cr>", desc = "Toggle symbol outline" },
			{
				"<leader>fs",
				function()
					require("aerial").snacks_picker()
				end,
				desc = "Current file symbols",
			},
		},
	},
	{
		"folke/flash.nvim",
		opts = {},
		keys = {
			{
				"s",
				function()
					require("flash").jump()
				end,
				mode = { "n", "x", "o" },
				desc = "Flash jump",
			},
			{
				"S",
				function()
					require("flash").treesitter()
				end,
				mode = { "n", "x", "o" },
				desc = "Flash treesitter",
			},
		},
	},
}
