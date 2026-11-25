local M = {}

local function select(items, prompt, callback, format)
	vim.ui.select(items, { prompt = prompt, format_item = format }, function(item)
		if item then
			callback(item)
		end
	end)
end

local function grep_fallback(initial, root)
	vim.g.dotfiles_last_picker = "grep_fallback"
	vim.ui.input({ prompt = "Search workspace (Vim regex): ", default = initial }, function(pattern)
		if not pattern or pattern == "" then
			return
		end
		-- globpath supplies filenames as data, never as Ex command fragments.
		local files = vim.fn.globpath(root or vim.fn.getcwd(), "**/*", false, true)
		local results = {}
		local ok, regex = pcall(vim.regex, pattern)
		if not ok then
			vim.notify("Invalid search expression", vim.log.levels.WARN)
			return
		end
		for _, file in ipairs(files) do
			local stat = vim.uv.fs_stat(file)
			if stat and stat.type == "file" and stat.size < 1024 * 1024 then
				local readable, lines = pcall(vim.fn.readfile, file)
				if readable then
					for number, line in ipairs(lines) do
						local start = regex:match_str(line)
						if start then
							table.insert(results, { filename = file, lnum = number, col = start + 1, text = line })
						end
					end
				end
			end
		end
		vim.fn.setqflist({}, "r", { title = "Search: " .. pattern, items = results })
		vim.cmd("copen")
	end)
end

M.grep_fallback = grep_fallback

function M.project_picker()
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("Project picker requires Snacks", vim.log.levels.WARN)
		return
	end
	local items, seen = {}, {}
	local function add(path)
		if path and not seen[path] then
			seen[path] = true
			table.insert(items, { file = path, text = path, dir = true })
		end
	end
	add(require("themizzi.dashboard").project())
	for i, file in ipairs(vim.v.oldfiles) do
		if i > 300 then
			break
		end
		add(vim.fs.root(file, ".git"))
	end
	local dev = vim.fn.expand("~/GitHub")
	local scan = vim.uv.fs_scandir(dev)
	if scan then
		while true do
			local name = vim.uv.fs_scandir_next(scan)
			if not name then
				break
			end
			local path = vim.fs.joinpath(dev, name)
			if vim.uv.fs_stat(vim.fs.joinpath(path, ".git")) then
				add(path)
			end
		end
	end
	snacks.picker({
		title = "Projects",
		items = items,
		format = "file",
		confirm = function(picker, item)
			if not item or not item.file then
				return
			end
			picker:close()
			local changed, err = pcall(vim.cmd.tcd, vim.fn.fnameescape(item.file))
			if not changed then
				vim.notify("Could not switch project: " .. tostring(err), vim.log.levels.ERROR)
				return
			end
			vim.schedule(function()
				snacks.dashboard()
			end)
		end,
	})
end

function M.setup()
	local has_which_key, which_key = pcall(require, "which-key")
	if has_which_key then
		which_key.add({
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Git" },
			{ "<leader>o", group = "OpenCode" },
			{ "<leader>c", group = "Code" },
			{ "<leader>t", group = "Todo" },
			{ "<leader>u", group = "UI" },
		})
	end
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
	end
	map("<C-h>", "<C-w>h", "Left pane")
	map("<C-j>", "<C-w>j", "Down pane")
	map("<C-k>", "<C-w>k", "Up pane")
	map("<C-l>", "<C-w>l", "Right pane")
	map("<leader>h", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			snacks.dashboard()
		else
			vim.notify("Dashboard requires Snacks", vim.log.levels.WARN)
		end
	end, "Project dashboard")
	map("<leader>fp", M.project_picker, "Switch project")
	map("<leader>uz", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			snacks.zen()
		else
			vim.notify("Zen mode requires Snacks", vim.log.levels.WARN)
		end
	end, "Toggle Zen mode")
	local function git_action(action)
		local root = vim.fs.root(vim.fn.getcwd(), ".git")
		if not root or vim.fn.executable("git") ~= 1 then
			vim.notify("Git repository or Git executable not found", vim.log.levels.WARN)
			return
		end
		action(root)
	end
	map("<leader>gg", function()
		git_action(function(root)
			local ok, snacks = pcall(require, "snacks")
			if ok then
				snacks.picker.git_status({ cwd = root })
			else
				vim.notify("Git status requires Snacks", vim.log.levels.WARN)
			end
		end)
	end, "Git status")
	map("<leader>gl", function()
		git_action(function(root)
			local ok, snacks = pcall(require, "snacks")
			if ok then
				snacks.picker.git_log({ cwd = root })
			else
				vim.notify("Git history requires Snacks", vim.log.levels.WARN)
			end
		end)
	end, "Git history")
	map("<leader>gd", function()
		git_action(function()
			if vim.fn.exists(":DiffviewOpen") == 2 then
				vim.cmd("DiffviewOpen")
			else
				vim.notify("Diffview is not installed", vim.log.levels.WARN)
			end
		end)
	end, "Git diff view")
	map("<leader>gf", function()
		git_action(function()
			if vim.api.nvim_buf_get_name(0) == "" then
				vim.notify("Open a file to see its Git history", vim.log.levels.WARN)
			elseif vim.fn.exists(":DiffviewFileHistory") == 2 then
				vim.cmd("DiffviewFileHistory %")
			else
				vim.notify("Diffview is not installed", vim.log.levels.WARN)
			end
		end)
	end, "Current file history")
	map("<leader>ff", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			vim.g.dotfiles_last_picker = "find_files"
			snacks.picker.files()
		else
			local files = vim.fn.globpath(vim.fn.getcwd(), "**/*", false, true)
			files = vim.tbl_filter(function(file)
				return vim.fn.filereadable(file) == 1
			end, files)
			select(files, "Files", function(file)
				vim.cmd.edit(vim.fn.fnameescape(file))
			end)
		end
	end, "Files")
	map("<leader>fb", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			vim.g.dotfiles_last_picker = "buffers"
			snacks.picker.buffers()
		else
			select(vim.fn.getbufinfo({ buflisted = 1 }), "Buffers", function(buffer)
				vim.api.nvim_set_current_buf(buffer.bufnr)
			end, function(buffer)
				return buffer.name == "" and "[No Name]" or buffer.name
			end)
		end
	end, "Buffers")
	map("<leader>fc", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			vim.g.dotfiles_last_picker = "commands"
			snacks.picker.commands()
		else
			select(vim.fn.getcompletion("", "command"), "Commands (edit arguments, then Enter)", function(command)
				vim.api.nvim_feedkeys(":" .. command .. " ", "n", false)
			end)
		end
	end, "Commands")
	map("<leader>fh", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			vim.g.dotfiles_last_picker = "help_tags"
			snacks.picker.help()
		else
			select(vim.fn.getcompletion("", "help"), "Help", function(tag)
				vim.cmd.help(tag)
			end)
		end
	end, "Help tags")
	map("<leader>fg", function()
		local has_rg = (vim.fn.executable("rg") == 1 or vim.g.dotfiles_force_has_rg == 1)
			and vim.g.dotfiles_force_no_rg ~= 1
		if has_rg then
			local ok, snacks = pcall(require, "snacks")
			if ok then
				vim.g.dotfiles_last_picker = "live_grep"
				snacks.picker.grep()
			else
				grep_fallback()
			end
		else
			grep_fallback()
		end
	end, "Search workspace")
	map("<leader>fk", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			vim.g.dotfiles_last_picker = "keymaps"
			snacks.picker.keymaps()
		else
			vim.cmd("verbose map")
		end
	end, "Search keymaps")
	map("<leader>e", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			snacks.explorer()
		else
			vim.cmd("Lexplore")
		end
	end, "Explorer")
	map("<leader>fe", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			snacks.explorer.reveal()
		else
			vim.cmd("Lexplore")
		end
	end, "Reveal current file")
	for lhs, method in pairs({ ["<leader>tn"] = "jump_next", ["<leader>tp"] = "jump_prev" }) do
		map(lhs, function()
			local ok, todo = pcall(require, "todo-comments")
			if ok then
				todo[method]()
			else
				vim.notify("TODO navigation requires the explicit plugin setup", vim.log.levels.WARN)
			end
		end, method == "jump_next" and "Next todo" or "Previous todo")
	end
	for lhs, command in pairs({
		["<leader>tl"] = "TodoLocList",
		["<leader>tq"] = "TodoQuickFix",
	}) do
		map(lhs, function()
			if vim.fn.exists(":" .. command) == 2 then
				vim.cmd(command)
			else
				vim.notify(command .. " requires the explicit plugin setup", vim.log.levels.WARN)
			end
		end, command)
	end
	map("<leader>tf", function()
		local ok, snacks = pcall(require, "snacks")
		if ok and vim.fn.executable("rg") == 1 then
			snacks.picker.grep({ search = "TODO|FIXME|HACK|NOTE" })
		else
			grep_fallback([[\vTODO|FIXME|HACK|NOTE]])
		end
	end, "Find TODO comments")
	map("<leader>ts", function()
		local ok, snacks = pcall(require, "snacks")
		local has_rg = (vim.fn.executable("rg") == 1 or vim.g.dotfiles_force_has_rg == 1)
			and vim.g.dotfiles_force_no_rg ~= 1
		if ok and has_rg then
			vim.g.dotfiles_last_picker = "live_grep_todos"
			snacks.picker.grep({ search = "TODO|FIXME|HACK|NOTE" })
		else
			grep_fallback([[\vTODO|FIXME|HACK|NOTE]])
		end
	end, "Search todos")
	local function format_buffer()
		local ok, conform = pcall(require, "conform")
		if ok then
			conform.format({ async = true, lsp_format = "fallback" })
		else
			vim.lsp.buf.format({ async = true })
		end
	end
	map("<leader>m", format_buffer, "Format buffer")
	map("<leader>cf", format_buffer, "Format buffer")
	map("<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
	map("<leader>cd", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, "Line diagnostics")
	map("<leader>cD", function()
		local ok, snacks = pcall(require, "snacks")
		if ok then
			snacks.picker.diagnostics_buffer()
		else
			vim.diagnostic.setloclist()
		end
	end, "File diagnostics")
	vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
	-- Native gcc is itself a mapping, so allow remapping for this alias.
	vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
	map("<leader>?", function()
		local ok, wk = pcall(require, "which-key")
		if ok then
			wk.show()
		else
			vim.cmd("map <Space>")
		end
	end, "Show mappings")
	map("<leader>r", "<cmd>registers<CR>", "Show registers")
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("DotfilesMarkdownMappings", { clear = true }),
		pattern = "markdown",
		callback = function(event)
			vim.keymap.set("n", "<leader>um", function()
				local ok, render = pcall(require, "render-markdown")
				if ok then
					render.buf_toggle()
				else
					vim.notify("Markdown rendering is not installed", vim.log.levels.WARN)
				end
			end, { buffer = event.buf, silent = true, desc = "Toggle Markdown rendering" })
		end,
	})
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("DotfilesNativeCompletion", { clear = true }),
		callback = function(event)
			-- Blink owns full-mode completion; manually attached LSPs still work offline.
			if package.loaded["blink.cmp"] then
				return
			end
			local client = vim.lsp.get_client_by_id(event.data.client_id)
			if client and client:supports_method("textDocument/completion") then
				vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
			end
		end,
	})
end

return M
