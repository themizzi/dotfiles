local M = {}

local function extend_specs(specs, module_name)
	local ok, module = pcall(require, module_name)
	if not ok then
		vim.notify("Failed to load " .. module_name, vim.log.levels.ERROR)
		return
	end

	for _, spec in ipairs(module) do
		specs[#specs + 1] = spec
	end
end

function M.specs()
	local specs = {}

	extend_specs(specs, "themizzi.plugins.ai")
	extend_specs(specs, "themizzi.plugins.ui")
	extend_specs(specs, "themizzi.plugins.lsp")
	extend_specs(specs, "themizzi.plugins.navigation")
	extend_specs(specs, "themizzi.plugins.editor")
	extend_specs(specs, "themizzi.plugins.git")

	return specs
end

return M
