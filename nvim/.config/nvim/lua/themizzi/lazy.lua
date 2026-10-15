local M = {}
M.commit = "6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a" -- lazy.nvim v11.17.1
M.path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

function M.setup()
	if vim.env.DOTFILES_SKIP_PLUGIN_BOOTSTRAP == "1" then
		return
	end
	if not vim.uv.fs_stat(M.path .. "/lua/lazy/init.lua") then
		return -- Offline baseline; installation is always an explicit action.
	end
	vim.opt.rtp:prepend(M.path)
	-- lazy rewrites its working lock during installs; keep the reviewed source
	-- read-only and seed a disposable working copy for each session.
	local lockfile = vim.fn.stdpath("data") .. "/dotfiles-lazy-lock.json"
	vim.fn.writefile(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), lockfile)
	require("lazy").setup(require("themizzi.plugins").specs(), {
		lockfile = lockfile,
		install = { missing = false },
		checker = { enabled = false },
		change_detection = { enabled = false },
	})
end

return M
