local M = {}

local function ensure_lazy()
  local lazyPath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazyPath) then
    if vim.fn.executable("git") ~= 1 then
      return false
    end
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazyPath,
    })
    if vim.v.shell_error ~= 0 then
      return false
    end
  end

  vim.opt.rtp:prepend(lazyPath)
  return true
end

local function configure_plugins()
  if vim.env.DOTFILES_SKIP_PLUGIN_BOOTSTRAP == "1" then
    return
  end

  if not ensure_lazy() then
    return
  end

  local ok, lazy = pcall(require, "lazy")
  if not ok then
    return
  end

  lazy.setup({
    {
      "ibhagwan/fzf-lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        local has_fzf, fzf = pcall(require, "fzf-lua")
        if has_fzf then
          fzf.setup({})
        end
      end,
    },
  }, {
    change_detection = { enabled = false },
  })
end

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

function M.setup()
  configure_plugins()

  vim.keymap.set("n", "<leader>p", invoke_picker("files"), { silent = true })
  vim.keymap.set("n", "<leader>b", invoke_picker("buffers"), { silent = true })
  vim.keymap.set("n", "<leader>c", invoke_picker("commands"), { silent = true })
  vim.keymap.set("n", "<leader>g", live_grep_or_fallback, { silent = true })
  vim.keymap.set("n", "<leader>h", invoke_picker("helptags"), { silent = true })
end

return M
