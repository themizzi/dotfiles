return {
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false } },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				per_filetype = { opencode_ask = { "lsp", "buffer" } },
			},
			-- Never download a Rust binary from normal startup.
			fuzzy = { implementation = "lua" },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main", -- Neovim 0.12 API, also pinned in lazy-lock.json.
		lazy = false,
		config = function()
			require("themizzi.treesitter").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		cmd = { "LspInstall", "LspUninstall" },
		dependencies = { { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } }, "neovim/nvim-lspconfig" },
		opts = { ensure_installed = {}, automatic_enable = false },
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
			"saghen/blink.cmp",
		},
		config = function()
			-- Mason must add its bin directory before checking executables.
			assert(require("mason").has_setup, "Mason must initialize before LSP executable detection")
			local servers = require("themizzi.servers")
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			for server, executable in pairs(servers) do
				if vim.fn.executable(executable) == 1 then
					vim.lsp.config(server, { capabilities = capabilities })
					vim.lsp.enable(server)
				end
			end
		end,
	},
}
