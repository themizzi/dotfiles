vim.g.dotfiles_force_has_rg = 1
local calls = {}
package.loaded["snacks"] = { picker = {} }
for _, name in ipairs({ "files", "buffers", "commands", "grep", "help", "keymaps" }) do
	package.loaded["snacks"].picker[name] = function()
		table.insert(calls, name)
	end
end
require("themizzi.keymaps").setup()
for _, key in ipairs({ "ff", "fb", "fc", "fg", "fh", "fk" }) do
	vim.fn.maparg(" " .. key, "n", false, true).callback()
end
assert(table.concat(calls, ",") == "files,buffers,commands,grep,help,keymaps")
