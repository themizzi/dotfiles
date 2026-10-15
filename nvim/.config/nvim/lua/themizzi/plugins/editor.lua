return {
	{ "tpope/vim-sleuth" },
	{ "kylechui/nvim-surround", opts = {} },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = { check_ts = true } },
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cmd = { "TodoLocList", "TodoQuickFix", "TodoFzfLua" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"andythigpen/nvim-coverage",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("coverage").setup({
				commands = true, auto_reload = true,
				signs = { covered = { hl = "CoverageCovered", text = "▎" }, uncovered = { hl = "CoverageUncovered", text = "▎" } },
				lang = { typescript = { coverage_file = "coverage/lcov.info" }, javascript = { coverage_file = "coverage/lcov.info" } },
			})
			vim.api.nvim_create_autocmd("BufEnter", {
				group = vim.api.nvim_create_augroup("DotfilesCoverage", { clear = true }),
				callback = function()
					if vim.fn.filereadable("coverage/lcov.info") == 1 then vim.cmd("Coverage") end
				end,
			})
		end,
	},
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
				json = { "jq", "prettierd", "prettier", stop_after_first = true },
				yaml = { "yq", "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" }, python = { "ruff_format", "black", stop_after_first = true },
				rust = { "rustfmt" },
			},
		},
	},
}
