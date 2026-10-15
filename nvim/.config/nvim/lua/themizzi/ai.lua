local M = {}

function M.setup()
	-- No buffer content is sent. Only an explicitly supplied prompt is transmitted.
	vim.api.nvim_create_user_command("DotfilesAI", function(args)
		local endpoint, model = vim.env.DOTFILES_NVIM_AI_ENDPOINT, vim.env.DOTFILES_NVIM_AI_MODEL
		if not endpoint or not model or vim.fn.executable("curl") ~= 1 then
			vim.notify("Set DOTFILES_NVIM_AI_ENDPOINT and DOTFILES_NVIM_AI_MODEL; install curl", vim.log.levels.ERROR)
			return
		end
		local headers = "Content-Type: application/json\n"
		if vim.env.DOTFILES_NVIM_AI_API_KEY then
			headers = headers .. "Authorization: Bearer " .. vim.env.DOTFILES_NVIM_AI_API_KEY .. "\n"
		end
		-- Headers (including any API key) travel over stdin, not process arguments.
		local body = vim.json.encode({ model = model, messages = { { role = "user", content = args.args } } })
		local file = vim.fn.tempname()
		vim.fn.writefile({ body }, file)
		vim.fn.setfperm(file, "rw-------")
		vim.system({ "curl", "--silent", "--show-error", "--fail-with-body", "--max-time", "120",
			"--header", "@-", "--data-binary", "@" .. file, endpoint }, { stdin = headers, text = true }, function(result)
			vim.schedule(function()
				vim.fn.delete(file)
				local ok, response = pcall(vim.json.decode, result.stdout or "")
				if result.code ~= 0 or not ok or type(response) ~= "table" or type(response.choices) ~= "table"
					or type(response.choices[1]) ~= "table" or type(response.choices[1].message) ~= "table" then
					vim.notify("AI request failed (curl exit " .. result.code .. "): " .. (result.stderr or "invalid response"), vim.log.levels.ERROR)
					return
				end
				vim.cmd("new")
				vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
				vim.bo.filetype = "markdown"
				vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(response.choices[1].message.content or "", "\n"))
			end)
		end)
	end, { nargs = "+", desc = "Send an explicit prompt to an opt-in OpenAI-compatible endpoint" })
end

return M
