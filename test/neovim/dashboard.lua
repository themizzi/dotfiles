local dashboard = require("themizzi.dashboard")
local base = vim.fn.getcwd()
local gitroot = base .. "/project with spaces"
local nested = gitroot .. "/src/nested"
local plain = base .. "/plain project"
vim.fn.mkdir(nested, "p")
vim.fn.mkdir(plain, "p")
local init = vim.system({ "git", "init", "-q", gitroot }, { text = true }):wait()
assert(init.code == 0, init.stderr)
local root, is_git = dashboard.project(nested)
assert(root == vim.fs.normalize(gitroot) and is_git, root)
root, is_git = dashboard.project(plain)
assert(root == vim.fs.normalize(plain) and not is_git, root)
assert(dashboard.parse_status("## main\n") == "main  ·  clean")
assert(dashboard.parse_status("## main...origin/main\n M file\n?? new file\n") == "main  ·  2 changed")
assert(dashboard.parse_status("## No commits yet on main\n") == "main  ·  clean")
assert(dashboard.parse_status("invalid") == nil)

local received, called = nil, {}
package.loaded["snacks.dashboard"] = {
	sections = {
		recent_files = function(opts)
			received = opts
			return function()
				return {}
			end
		end,
	},
}
package.loaded["snacks"] = {
	picker = {
		files = function(opts)
			called.files = opts.cwd
		end,
		grep = function(opts)
			called.grep = opts.cwd
		end,
	},
	explorer = function(opts)
		called.explorer = opts.cwd
	end,
}
vim.cmd.cd(vim.fn.fnameescape(plain))
local sections = dashboard.sections({ buf = -1 })
assert(received.cwd == vim.fs.normalize(plain) and received.limit == 6)
assert(sections[13][1].text == "No recent files in this project")
sections[5].action()
assert(called.files == vim.fs.normalize(plain))
sections[7].action()
sections[10].action()
assert(called.files == vim.fn.stdpath("config"))
assert(called.explorer == vim.fs.normalize(plain))
assert(vim.fn.getcwd() == plain)
local spec = require("themizzi.plugins.navigation")[1]
assert(spec.opts.dashboard.enabled and type(spec.opts.dashboard.sections[1]) == "function")
assert(vim.fn.maparg(" h", "n") ~= "")

local oldpath = vim.env.PATH
vim.env.PATH = ""
local km = require("themizzi.keymaps")
local original = km.grep_fallback
local fallback_root
km.grep_fallback = function(_, dir)
	fallback_root = dir
end
sections[6].action()
km.grep_fallback = original
vim.env.PATH = oldpath
assert(fallback_root == vim.fs.normalize(plain))
vim.cmd.cd(vim.fn.fnameescape(nested))
local real_system = vim.system
local calls, callback = {}, nil
vim.system = function(args, opts, cb)
	calls[#calls + 1] = { args = args, opts = opts }
	callback = cb
	return {}
end
local git_dashboard = { buf = -1 }
local pending = dashboard.sections(git_dashboard)
dashboard.sections(git_dashboard)
assert(#calls == 1)
assert(calls[1].args[1] == "git" and calls[1].args[5] == "-C")
assert(calls[1].args[6] == gitroot and calls[1].opts.timeout == 1500)
callback({ code = 0, stdout = "## main\n M file\n" })
assert(vim.wait(1000, function()
	local result = dashboard.sections(git_dashboard)
	return result[3].text == "Git: main  ·  1 changed"
end))
assert(#calls == 1)
vim.env.PATH = ""
local before = #calls
local without_git = dashboard.sections({ buf = -1 })
assert(#calls == before and without_git[3].text == nil)
vim.env.PATH = oldpath
vim.system = real_system
