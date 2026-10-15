return {
	{ "tpope/vim-sleuth" },
	{ "kylechui/nvim-surround", opts = {} },
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = { lsp_format = "fallback", timeout_ms = 500 },
			formatters_by_ft = {
				sh = { "shfmt" }, bash = { "shfmt" }, go = { "gofmt" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" }, python = { "ruff_format", "black", stop_after_first = true },
				rust = { "rustfmt" },
			},
		},
	},
}
