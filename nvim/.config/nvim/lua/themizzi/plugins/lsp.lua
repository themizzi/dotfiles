return {
	{
		"mason-org/mason-lspconfig.nvim",
		cmd = { "LspInstall", "LspUninstall" },
		dependencies = { { "mason-org/mason.nvim", opts = {} }, "neovim/nvim-lspconfig" },
		opts = { ensure_installed = {}, automatic_enable = false },
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
		},
		config = function()
			-- Mason must add its bin directory before checking executables.
			assert(require("mason").has_setup, "Mason must initialize before LSP executable detection")
			local servers = {
				lua_ls = "lua-language-server", pyright = "pyright-langserver",
				ts_ls = "typescript-language-server", gopls = "gopls",
				rust_analyzer = "rust-analyzer", bashls = "bash-language-server",
			}
			local missing = {}
			for server, executable in pairs(servers) do
				if vim.fn.executable(executable) == 1 then
					vim.lsp.config(server, { capabilities = vim.lsp.protocol.make_client_capabilities() })
					vim.lsp.enable(server)
				else
					table.insert(missing, executable)
				end
			end
			if #missing > 0 then
				table.sort(missing)
				vim.schedule(function()
					vim.notify("Optional LSP executables missing: " .. table.concat(missing, ", ") .. ". See docs/neovim.md or :Mason", vim.log.levels.WARN)
				end)
			end
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/completion") then
						vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
					end
				end,
			})
		end,
	},
}
