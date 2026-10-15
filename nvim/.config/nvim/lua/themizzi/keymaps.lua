local M = {}

local function picker(name, fallback)
	return function()
		local ok, fzf = pcall(require, "fzf-lua")
		if ok and (vim.fn.executable("fzf") == 1 or vim.g.dotfiles_capture_pickers == 1) then
			vim.g.dotfiles_last_picker = name
			fzf[name]()
		else
			vim.g.dotfiles_last_picker = name .. "_fallback"
			fallback()
		end
	end
end

local function select(items, prompt, callback, format)
	vim.ui.select(items, { prompt = prompt, format_item = format }, function(item)
		if item then callback(item) end
	end)
end

local function grep_fallback()
	vim.g.dotfiles_last_picker = "grep_fallback"
	vim.ui.input({ prompt = "Search workspace (Vim regex): " }, function(pattern)
		if not pattern or pattern == "" then return end
		-- globpath supplies filenames as data, never as Ex command fragments.
		local files = vim.fn.globpath(vim.fn.getcwd(), "**/*", false, true)
		local results = {}
		local ok, regex = pcall(vim.regex, pattern)
		if not ok then vim.notify("Invalid search expression", vim.log.levels.WARN); return end
		for _, file in ipairs(files) do
			local stat = vim.uv.fs_stat(file)
			if stat and stat.type == "file" and stat.size < 1024 * 1024 then
				local readable, lines = pcall(vim.fn.readfile, file)
				if readable then
					for number, line in ipairs(lines) do
						local start = regex:match_str(line)
						if start then table.insert(results, { filename = file, lnum = number, col = start + 1, text = line }) end
					end
				end
			end
		end
		vim.fn.setqflist({}, "r", { title = "Search: " .. pattern, items = results })
		vim.cmd("copen")
	end)
end

function M.setup()
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
	end
	map("<leader>ff", picker("files", function()
		local files = vim.fn.globpath(vim.fn.getcwd(), "**/*", false, true)
		files = vim.tbl_filter(function(file) return vim.fn.filereadable(file) == 1 end, files)
		select(files, "Files", function(file) vim.cmd.edit(vim.fn.fnameescape(file)) end)
	end), "Files")
	map("<leader>fb", picker("buffers", function()
		select(vim.fn.getbufinfo({ buflisted = 1 }), "Buffers", function(buffer)
			vim.api.nvim_set_current_buf(buffer.bufnr)
		end, function(buffer) return buffer.name == "" and "[No Name]" or buffer.name end)
	end), "Buffers")
	map("<leader>fc", picker("commands", function()
		select(vim.fn.getcompletion("", "command"), "Commands (edit arguments, then Enter)", function(command)
			vim.api.nvim_feedkeys(":" .. command .. " ", "n", false)
		end)
	end), "Commands")
	map("<leader>fh", picker("helptags", function()
		select(vim.fn.getcompletion("", "help"), "Help", function(tag) vim.cmd.help(tag) end)
	end), "Help tags")
	map("<leader>fg", function()
		local has_rg = (vim.fn.executable("rg") == 1 or vim.g.dotfiles_force_has_rg == 1) and vim.g.dotfiles_force_no_rg ~= 1
		if has_rg then picker("live_grep", grep_fallback)() else grep_fallback() end
	end, "Search workspace")
	map("<leader>e", function()
		if vim.fn.exists(":NvimTreeToggle") == 2 then vim.cmd("NvimTreeToggle") else vim.cmd("Lexplore") end
	end, "Explorer (tree or netrw)")
	map("<leader>m", function()
		local ok, conform = pcall(require, "conform")
		if ok then conform.format({ async = true, lsp_format = "fallback" })
		else vim.lsp.buf.format({ async = true }) end
	end, "Format buffer")
	vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
	-- Native gcc is itself a mapping, so allow remapping for this alias.
	vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
	map("<leader>?", function()
		local ok, wk = pcall(require, "which-key")
		if ok then wk.show() else vim.cmd("map <Space>") end
	end, "Show mappings")
	map("<leader>r", "<cmd>registers<CR>", "Show registers")
end

return M
