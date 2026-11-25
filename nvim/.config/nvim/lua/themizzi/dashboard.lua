local M = {}

-- Each dashboard keeps its own request state, so a slow Git process cannot
-- update a newer dashboard or keep re-running when the window is redrawn.
local states = setmetatable({}, { __mode = "k" })

function M.project(cwd)
	cwd = vim.fs.normalize(cwd or vim.fn.getcwd())
	local root = vim.fs.root(cwd, ".git")
	return root and vim.fs.normalize(root) or cwd, root ~= nil
end

function M.parse_status(output)
	local lines = vim.split(output or "", "\n", { plain = true, trimempty = true })
	local header = table.remove(lines, 1)
	if not header or not header:match("^## ") then
		return nil
	end
	local branch = header:sub(4):gsub("%.%.%..*$", ""):gsub("^No commits yet on ", "")
	return branch .. "  ·  " .. (#lines == 0 and "clean" or (#lines .. " changed"))
end

local function status(self, root, is_git)
	if not is_git or vim.fn.executable("git") ~= 1 then
		return nil
	end
	local state = states[self]
	if not state or state.root ~= root then
		state = { root = root, text = "Checking Git…" }
		states[self] = state
		local ok = pcall(vim.system, {
			"git",
			"--no-optional-locks",
			"-c",
			"core.fsmonitor=false",
			"-C",
			root,
			"status",
			"--porcelain=v1",
			"--branch",
		}, { text = true, timeout = 1500 }, function(result)
			vim.schedule(function()
				if states[self] ~= state then
					return
				end
				state.text = result.code == 0 and M.parse_status(result.stdout) or nil
				if self.win and vim.api.nvim_buf_is_valid(self.buf) and vim.api.nvim_win_is_valid(self.win) then
					self:update()
				end
			end)
		end)
		if not ok then
			state.text = nil
		end
	end
	return state.text
end

function M.sections(self)
	local root, is_git = M.project()
	local name = vim.fn.fnamemodify(root, ":t")
	if name == "" then
		name = root
	end
	local git = status(self, root, is_git)
	local recent = require("snacks.dashboard").sections.recent_files({ cwd = root, limit = 6 })()
	if #recent == 0 then
		recent = { { text = "No recent files in this project", indent = 2 } }
	end
	local function picker(method, opts)
		require("snacks").picker[method](opts)
	end
	return {
		{ header = name, padding = 1 },
		{ text = vim.fn.fnamemodify(root, ":~"), align = "center" },
		git and { text = "Git: " .. git, align = "center", padding = 1 } or {},
		{ title = "Actions", padding = 1 },
		{
			key = "f",
			desc = "Find files",
			icon = " ",
			action = function()
				picker("files", { cwd = root })
			end,
		},
		{
			key = "g",
			desc = "Search project",
			icon = " ",
			action = function()
				if vim.fn.executable("rg") == 1 then
					picker("grep", { cwd = root })
				else
					require("themizzi.keymaps").grep_fallback(nil, root)
				end
			end,
		},
		{
			key = "e",
			desc = "Explorer",
			icon = " ",
			action = function()
				require("snacks").explorer({ cwd = root })
			end,
		},
		{
			key = "p",
			desc = "Switch project",
			icon = "󰉋 ",
			action = function()
				require("themizzi.keymaps").project_picker()
			end,
		},
		{ key = "o", desc = "OpenCode terminal", icon = "󰚩 ", action = "<leader>ot" },
		{
			key = "c",
			desc = "Neovim config",
			icon = " ",
			action = function()
				picker("files", { cwd = vim.fn.stdpath("config") })
			end,
		},
		{ key = "q", desc = "Quit", icon = " ", action = ":qa" },
		{ title = "Recent files", padding = { 1, 1 } },
		recent,
	}
end

function M.config()
	return { enabled = true, sections = { M.sections } }
end

return M
