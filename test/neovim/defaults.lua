assert(vim.g.mapleader == " " and vim.o.number and vim.o.hidden)
assert(vim.o.cmdheight >= 0)
assert(vim.g.clipboard == nil and vim.o.clipboard == "")
assert(vim.fn.exists(":CodeCompanion") == 0 and not package.loaded.codecompanion)
for _, lhs in ipairs({ " ff", " fb", " fc", " fg", " fh", " e" }) do
	assert(vim.fn.maparg(lhs, "n") ~= "", "Missing mapping: " .. lhs)
end
