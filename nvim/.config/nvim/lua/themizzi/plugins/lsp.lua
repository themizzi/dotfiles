return {
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false } },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			-- Never download a Rust binary from normal startup.
			fuzzy = { implementation = "lua" },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master", -- Frozen legacy configs API, also pinned in lazy-lock.json.
		lazy = false,
		config = function()
			require("nvim-treesitter.configs").setup(require("themizzi.treesitter").opts)
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
			local missing = {}
			for server, executable in pairs(servers) do
				if vim.fn.executable(executable) == 1 then
					vim.lsp.config(server, { capabilities = capabilities })
					vim.lsp.enable(server)
				else
					table.insert(missing, executable)
				end
			end
			if #missing > 0 then
				table.sort(missing)
				vim.schedule(function()
					vim.notify(
						"Optional LSP executables missing: "
							.. table.concat(missing, ", ")
							.. ". See docs/neovim.md or :Mason",
						vim.log.levels.WARN
					)
				end)
			end
		end,
	},
}
