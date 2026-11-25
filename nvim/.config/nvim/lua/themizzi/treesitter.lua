local M = {}

-- Install only via explicit setup opt-in or :TSInstall, never on buffer open.
M.parsers = {
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
	"markdown",
	"markdown_inline",
	"vimdoc",
}

function M.setup()
	require("nvim-treesitter").setup({})
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
		callback = function(event)
			local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
			if not lang then
				return
			end
			local ok, available = pcall(vim.treesitter.language.add, lang)
			if ok and available then
				vim.treesitter.start(event.buf, lang)
				local has_query, query = pcall(vim.treesitter.query.get, lang, "indents")
				if has_query and query then
					vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end
		end,
	})
end

return M
