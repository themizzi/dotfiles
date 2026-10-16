local expected = {
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
local configured, enabled = {}, {}
package.loaded["mason"] = { has_setup = true }
package.loaded["blink.cmp"] = {
	get_lsp_capabilities = function()
		return { blink = true }
	end,
}
vim.fn.executable = function()
	return 1
end
vim.lsp.config = function(name, opts)
	configured[name] = opts
end
vim.lsp.enable = function(name)
	enabled[name] = true
end
for _, spec in ipairs(require("themizzi.plugins.lsp")) do
	if spec[1] == "neovim/nvim-lspconfig" then
		spec.config()
	end
end
assert(vim.tbl_count(configured) == 16)
for _, server in ipairs(expected) do
	assert(enabled[server] and configured[server].capabilities.blink, server)
end
