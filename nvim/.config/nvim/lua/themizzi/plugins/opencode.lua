local terminal_opts = { win = { position = "right", width = 0.4, enter = false } }

return {
	{
		"nickjvandyke/opencode.nvim",
		config = function()
			require("opencode.config").opts.server.start = function()
				require("snacks").terminal.open("opencode", terminal_opts)
			end
		end,
		keys = {
			{
				"<leader>ot",
				function()
					require("snacks").terminal.toggle("opencode", terminal_opts)
				end,
				desc = "Toggle OpenCode terminal",
			},
			{
				"<leader>oa",
				function()
					require("opencode").ask("@this: ")
				end,
				mode = { "n", "x" },
				desc = "Ask OpenCode",
			},
			{
				"<leader>os",
				function()
					require("opencode").select()
				end,
				mode = { "n", "x" },
				desc = "Select OpenCode action",
			},
			{
				"<leader>oe",
				function()
					require("opencode").prompt("Explain @this and its context")
				end,
				mode = { "n", "x" },
				desc = "OpenCode: explain",
			},
			{
				"<leader>or",
				function()
					require("opencode").prompt("Review @this for correctness and readability")
				end,
				mode = { "n", "x" },
				desc = "OpenCode: review",
			},
			{
				"<leader>od",
				function()
					require("opencode").prompt("Explain @diagnostics")
				end,
				mode = { "n", "x" },
				desc = "OpenCode: explain diagnostics",
			},
			{
				"go",
				function()
					return require("opencode").operator("@this")
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Send range to OpenCode",
			},
			{
				"goo",
				function()
					return require("opencode").operator("@this") .. "_"
				end,
				mode = "n",
				expr = true,
				desc = "Send line to OpenCode",
			},
		},
	},
}
