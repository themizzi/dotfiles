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

	extend_specs(specs, "themizzi.plugins.ui")
	extend_specs(specs, "themizzi.plugins.lsp")
	extend_specs(specs, "themizzi.plugins.navigation")
	extend_specs(specs, "themizzi.plugins.editor")
	extend_specs(specs, "themizzi.plugins.git")
	if vim.env.DOTFILES_NVIM_AI == "1" then
		extend_specs(specs, "themizzi.plugins.ai")
	end
	-- Treat the reviewed lock as the version policy, including :Lazy update.
	local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), "\n"))
	local function pin(items)
		for i, item in ipairs(items) do
			if type(item) == "string" then item = { item }; items[i] = item end
			local name = item[1]:match("/([^/]+)$")
			assert(lock[name], "Missing reviewed plugin revision: " .. name)
			item.commit = lock[name].commit
			item.branch = lock[name].branch
			if item.dependencies then pin(item.dependencies) end
		end
	end
	pin(specs)

	return specs
end

return M
