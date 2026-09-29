local M = {}

function M.setup()
	require("themizzi.options").setup()
	require("themizzi.lazy").setup()
	require("themizzi.keymaps").setup()
end

return M
