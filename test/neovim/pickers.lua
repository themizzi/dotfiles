vim.cmd("edit alpha.txt")
vim.g.dotfiles_force_no_rg = 1
vim.ui.input = function(_, callback)
	callback("needle")
end
vim.fn.maparg(" fg", "n", false, true).callback()
assert(vim.g.dotfiles_last_picker == "grep_fallback")
local entries = vim.fn.getqflist()
assert(#entries == 1 and entries[1].lnum == 2)
vim.ui.input = function(_, callback)
	callback(nil)
end
vim.fn.maparg(" fg", "n", false, true).callback()
assert(#vim.fn.getqflist() == 1)
