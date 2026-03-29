local M = {}

local function invoke_picker(name)
  return function()
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
      return
    end

    vim.g.dotfiles_last_picker = name

    if name == "files" then
      fzf.files()
    elseif name == "buffers" then
      fzf.buffers()
    elseif name == "commands" then
      fzf.commands()
    elseif name == "helptags" then
      fzf.helptags()
    end
  end
end

local function live_grep_or_fallback()
  local force_has_rg = vim.g.dotfiles_force_has_rg == 1
  local force_no_rg = vim.g.dotfiles_force_no_rg == 1
  local has_rg = (force_has_rg or vim.fn.executable("rg") == 1) and not force_no_rg
  local ok, fzf = pcall(require, "fzf-lua")

  if has_rg and ok then
    vim.g.dotfiles_last_picker = "live_grep"
    fzf.live_grep()
    return
  end

  vim.g.dotfiles_last_picker = "grep_fallback"
  vim.cmd("silent! vimgrep /./gj %")
end

local function format_current_buffer()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end

  conform.format({ async = true, lsp_fallback = true })
end

local function search_todos()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return
  end

  vim.g.dotfiles_last_picker = "todo_grep"
  fzf.live_grep({ search = "TODO|FIXME|HACK|NOTE" })
end

local function jump_todo(direction)
  local ok, todo = pcall(require, "todo-comments")
  if not ok then
    return
  end

  if direction == "next" then
    todo.jump_next()
  else
    todo.jump_prev()
  end
end

local function toggle_comment_line()
  local ok, api = pcall(require, "Comment.api")
  if not ok then
    return
  end

  api.toggle.linewise.current()
end

function M.setup()
  local ok, which_key = pcall(require, "which-key")
  if ok then
    which_key.add({
      { "<leader>f", group = "FZF" },
      { "<leader>g", group = "Git" },
      { "<leader>t", group = "Todo" },
    })
  end

  vim.keymap.set("n", "<leader>ff", invoke_picker("files"), { silent = true, desc = "Files" })
  vim.keymap.set("n", "<leader>fb", invoke_picker("buffers"), { silent = true, desc = "Buffers" })
  vim.keymap.set("n", "<leader>fc", invoke_picker("commands"), { silent = true, desc = "Commands" })
  vim.keymap.set("n", "<leader>fg", live_grep_or_fallback, { silent = true, desc = "Live grep" })
  vim.keymap.set("n", "<leader>fh", invoke_picker("helptags"), { silent = true, desc = "Help tags" })
  vim.keymap.set("n", "<leader>m", format_current_buffer, { silent = true, desc = "Format buffer" })
  vim.keymap.set("n", "<leader>/", toggle_comment_line, { silent = true, desc = "Toggle comment" })
  vim.keymap.set("n", "<leader>tn", function()
    jump_todo("next")
  end, { silent = true, desc = "Next todo" })
  vim.keymap.set("n", "<leader>tp", function()
    jump_todo("prev")
  end, { silent = true, desc = "Previous todo" })
  vim.keymap.set("n", "<leader>tl", "<cmd>TodoLocList<CR>", { silent = true, desc = "Todo list" })
  vim.keymap.set("n", "<leader>tq", "<cmd>TodoQuickFix<CR>", { silent = true, desc = "Todo quickfix" })
  vim.keymap.set("n", "<leader>tf", "<cmd>TodoFzfLua<CR>", { silent = true, desc = "Todo fzf" })
  vim.keymap.set("n", "<leader>ts", search_todos, { silent = true, desc = "Search todos" })
  vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { silent = true, desc = "Explorer" })
  vim.keymap.set("n", "<leader>fe", "<cmd>NvimTreeFindFile<CR>", { silent = true, desc = "Find file in tree" })
  vim.keymap.set("n", "*", "*", { desc = "Search word forward" })
  vim.keymap.set("n", "#", "#", { desc = "Search word backward" })
  vim.keymap.set("n", "<leader>?", function()
    local ok_show, wk = pcall(require, "which-key")
    if ok_show then
      wk.show()
    end
  end, { desc = "Show which-key" })
  vim.keymap.set("n", "<leader>r", ":registers<CR>", { desc = "Show registers" })
end

return M
