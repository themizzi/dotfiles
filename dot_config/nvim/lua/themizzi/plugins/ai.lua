return {
	{
		"olimorris/codecompanion.nvim",
		version = "^19.0.0",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
		},
		config = function()
			require("codecompanion").setup({
				adapters = {
					http = {
						lmstudio = function()
							return require("codecompanion.adapters").extend("openai_compatible", {
								env = {
									url = "http://127.0.0.1:1234",
									chat_url = "/v1/chat/completions",
								},
							})
						end,
					},
				},
				interactions = {
					chat = { adapter = "lmstudio" },
					inline = { adapter = "lmstudio" },
					cmd = { adapter = "lmstudio" },
				},
			})
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "codecompanion" },
	},
	{
		"HakonHarnes/img-clip.nvim",
		opts = {
			filetypes = {
				codecompanion = {
					prompt_for_file_name = false,
					template = "[Image]($FILE_PATH)",
					use_absolute_path = true,
				},
			},
		},
	},
}
