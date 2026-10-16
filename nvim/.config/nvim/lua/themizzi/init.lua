local M = {}

function M.setup()
	if vim.fn.has("nvim-0.11.3") == 0 then
		vim.notify(
			"Dotfiles full configuration requires Neovim >= 0.11.3; using shared Vim defaults",
			vim.log.levels.WARN
		)
		return
	end
	require("themizzi.options").setup()
	require("themizzi.lazy").setup()
	require("themizzi.keymaps").setup()
end

return M
