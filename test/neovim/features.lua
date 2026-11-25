local specs = require("themizzi.plugins").specs()
local byname = {}
for _, spec in ipairs(specs) do
	byname[spec[1]] = spec
end
local nav = byname["folke/snacks.nvim"].opts
assert(nav.zen.enabled and nav.zen.win.width == 100)
local explorer = nav.picker.sources.explorer.win.list.keys
assert(explorer.a[1] == "explorer_add" and explorer.a.desc)
assert(explorer.d[1] == "explorer_del" and explorer.H[1] == "toggle_hidden")

local ui = byname["nvim-lualine/lualine.nvim"].opts
local status = ui.sections.lualine_x[1]
package.loaded["opencode.events.status"] = nil
assert(status() == "" and package.loaded["opencode.events.status"] == nil)
package.loaded["opencode.events.status"] = {
	statusline = function()
		return "busy"
	end,
}
assert(status() == "busy")
package.loaded["opencode.events.status"] = nil
local md = byname["MeanderingProgrammer/render-markdown.nvim"].opts
assert(md.heading.width == "block" and md.code.language and md.checkbox.checked.icon)

local actions, opened, shown = {}, nil, false
local aerial = byname["stevearc/aerial.nvim"]
local symbol_mapping
for _, key in ipairs(aerial.keys) do
	if key[1] == "<leader>fs" then
		symbol_mapping = key[2]
	end
end
assert(type(symbol_mapping) == "function")
package.loaded["aerial"] = {
	snacks_picker = function()
		actions.symbols = true
	end,
}
symbol_mapping()
assert(actions.symbols)
local picker = setmetatable({
	git_status = function(opts)
		actions.git_status = opts.cwd
	end,
	git_log = function(opts)
		actions.git_log = opts.cwd
	end,
}, {
	__call = function(_, opts)
		opened = opts
	end,
})
package.loaded["snacks"] = {
	picker = picker,
	zen = function()
		actions.zen = true
	end,
	dashboard = function()
		shown = true
	end,
}
local km = require("themizzi.keymaps")
km.setup()
vim.fn.maparg(" uz", "n", false, true).callback()
assert(actions.zen)
local original_notify = vim.notify
local notice
vim.notify = function(msg)
	notice = msg
end
vim.fn.maparg(" gg", "n", false, true).callback()
assert(notice and notice:find("Git repository", 1, true))
vim.notify = original_notify

local base = vim.fn.getcwd()
local repo = base .. "/repository with spaces"
vim.fn.mkdir(repo, "p")
local result = vim.system({ "git", "init", "-q", repo }, { text = true }):wait()
assert(result.code == 0, result.stderr)
vim.cmd.cd(vim.fn.fnameescape(repo))
vim.fn.maparg(" gg", "n", false, true).callback()
vim.fn.maparg(" gl", "n", false, true).callback()
assert(actions.git_status == repo and actions.git_log == repo)
local unsaved = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(unsaved, 0, -1, false, { "unsaved changes" })
km.project_picker()
assert(opened and #opened.items >= 1)
local closed = false
opened.confirm({
	close = function()
		closed = true
	end,
}, { file = repo })
assert(closed and vim.fn.getcwd() == repo)
assert(vim.api.nvim_buf_is_valid(unsaved) and vim.bo[unsaved].modified)
assert(vim.wait(1000, function()
	return shown
end))

local toggled = false
package.loaded["render-markdown"] = {
	buf_toggle = function()
		toggled = true
	end,
}
vim.cmd("enew")
vim.bo.filetype = "markdown"
local mapping = vim.fn.maparg(" um", "n", false, true)
assert(mapping.buffer == 1)
mapping.callback()
assert(toggled)

local oc = byname["nickjvandyke/opencode.nvim"]
local prompts = {}
package.loaded["opencode"] = {
	prompt = function(text)
		prompts[#prompts + 1] = text
	end,
}
for _, key in ipairs(oc.keys) do
	if key[1] == "<leader>oe" or key[1] == "<leader>or" or key[1] == "<leader>od" then
		key[2]()
	end
end
assert(
	table.concat(prompts, "|")
		== "Explain @this and its context|Review @this for correctness and readability|Explain @diagnostics"
)
