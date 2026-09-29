return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = { auto_show = false },
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "codecompanion" },
			},
			fuzzy = {
				implementation = "prefer_rust_with_warning",
			},
		},
		opts_extend = { "sources.default" },
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local ok, treesitter = pcall(require, "nvim-treesitter.configs")
			if not ok then
				return
			end

			treesitter.setup({
				ensure_installed = {
					"bash",
					"css",
					"go",
					"html",
					"javascript",
					"json",
					"lua",
					"python",
					"regex",
					"rust",
					"toml",
					"tsx",
					"typescript",
					"vim",
					"yaml",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				automatic_installation = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local servers = {
				"ts_ls",
				"tailwindcss",
				"lua_ls",
				"rust_analyzer",
				"pyright",
				"gopls",
				"yamlls",
				"jsonls",
				"html",
				"cssls",
				"astro",
				"emmet_ls",
				"graphql",
				"bashls",
				"dockerls",
				"clangd",
			}

			for _, server in ipairs(servers) do
				vim.lsp.config(server, {
					capabilities = capabilities,
				})
				vim.lsp.enable(server)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if not client or client.name ~= "pyright" then
						return
					end

					if client.supports_method("textDocument/semanticTokens/full") then
						pcall(vim.lsp.semantic_tokens.enable, args.buf, client.id)
					end
				end,
			})
		end,
	},
}
