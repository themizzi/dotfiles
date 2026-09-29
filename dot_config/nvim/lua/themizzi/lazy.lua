local M = {}

local function ensure_lazy()
	local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.loop.fs_stat(lazy_path) then
		if vim.fn.executable("git") ~= 1 then
			return false
		end

		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazy_path,
		})

		if vim.v.shell_error ~= 0 then
			return false
		end
	end

	vim.opt.rtp:prepend(lazy_path)
	return true
end

function M.setup()
	if vim.env.DOTFILES_SKIP_PLUGIN_BOOTSTRAP == "1" then
		return
	end

	if not ensure_lazy() then
		return
	end

	local ok, lazy = pcall(require, "lazy")
	if not ok then
		return
	end

	lazy.setup(require("themizzi.plugins").specs(), {
		change_detection = { enabled = false },
	})
end

return M
