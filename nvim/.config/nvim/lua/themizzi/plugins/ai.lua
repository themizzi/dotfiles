-- CodeCompanion v17.33.0 retains the strategies API used by MCPHub v6.2.0.
-- This entire module is excluded unless DOTFILES_NVIM_AI=1.
local with_mcp = vim.env.DOTFILES_NVIM_MCP == "1"
local dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" }
if with_mcp then table.insert(dependencies, "ravitemer/mcphub.nvim") end

return {
	{
		"olimorris/codecompanion.nvim",
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
		dependencies = dependencies,
		opts = function()
			local model = vim.env.DOTFILES_NVIM_AI_MODEL or "local-model"
			return {
				adapters = {
					http = {
						opts = { show_presets = false },
						lmstudio = function()
							return require("codecompanion.adapters").extend("openai_compatible", {
								-- Use the complete URL; no hard-coded host/path concatenation.
								url = vim.env.DOTFILES_NVIM_AI_ENDPOINT or "http://127.0.0.1:1234/v1/chat/completions",
								env = { api_key = "DOTFILES_NVIM_AI_API_KEY" },
								headers = vim.env.DOTFILES_NVIM_AI_API_KEY and {
									["Content-Type"] = "application/json", Authorization = "Bearer ${api_key}",
								} or { ["Content-Type"] = "application/json", Authorization = "" },
								-- Never query /models implicitly: both default and choices are local.
								schema = { model = { default = model, choices = { model } } },
							})
						end,
					},
				},
				strategies = {
					chat = { adapter = "lmstudio", opts = { completion_provider = "blink" } },
					inline = { adapter = "lmstudio" },
					cmd = { adapter = "lmstudio" },
				},
				extensions = with_mcp and {
					mcphub = { callback = "mcphub.extensions.codecompanion", opts = {} },
				} or {},
			}
		end,
	},
	{
		"ravitemer/mcphub.nvim",
		cmd = "MCPHub",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { use_bundled_binary = false, auto_approve = false, auto_toggle_mcp_servers = false },
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "codecompanion" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = { file_types = { "markdown", "codecompanion" } },
	},
	{
		"HakonHarnes/img-clip.nvim",
		cmd = "PasteImage",
		opts = {
			filetypes = {
				codecompanion = { prompt_for_file_name = false, template = "[Image]($FILE_PATH)", use_absolute_path = true },
			},
		},
	},
}
