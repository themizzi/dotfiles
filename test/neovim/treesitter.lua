local ts = vim.treesitter
local old = {
	add = ts.language.add,
	get_lang = ts.language.get_lang,
	query = ts.query.get,
	start = ts.start,
}
local setups, starts = 0, 0
package.loaded["nvim-treesitter"] = {
	setup = function()
		setups = setups + 1
	end,
}
ts.language.add = function()
	return true
end
ts.language.get_lang = function()
	return "testlang"
end
ts.start = function()
	starts = starts + 1
end

local query
ts.query.get = function(_, name)
	assert(name == "indents")
	if query == "error" then
		error("invalid query")
	end
	return query
end
require("themizzi.treesitter").setup()
assert(setups == 1)
local buf = vim.api.nvim_create_buf(true, false)
vim.bo[buf].filetype = "dotfiles_test"
vim.bo[buf].indentexpr = "ExistingIndent()"
vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
assert(starts > 0 and vim.bo[buf].indentexpr == "ExistingIndent()")
query = "error"
vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
assert(vim.bo[buf].indentexpr == "ExistingIndent()")
query = {}
vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
assert(vim.bo[buf].indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()")

ts.language.add = old.add
ts.language.get_lang = old.get_lang
ts.query.get = old.query
ts.start = old.start
