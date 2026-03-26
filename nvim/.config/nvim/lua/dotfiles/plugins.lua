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
      "williamboman/mason.nvim",
      cmd = "Mason",
      config = function()
        require("mason").setup({
          ui = {
            border = "rounded",
          },
        })
      end,
    },
    {
      "williamboman/mason-lspconfig.nvim",
      config = function()
        require("mason-lspconfig").setup({
          automatic_installation = true,
        })
      end,
    },
    {
      "neovim/nvim-lspconfig",
      config = function()
        local servers = {
          "ts_ls",
          "tailwindcss",
          "lua_ls",
          "rust_analyzer",
          "pyright",
          "gopls",
          "yamlls",
          "jsonls",
          "html",
          "cssls",
          "astro",
          "emmet_ls",
          "graphql",
          "jsonls",
          "bashls",
          "dockerls",
          "clangd",
        }

        for _, server in ipairs(servers) do
          vim.lsp.enable(server)
        end
      end,
    },
    {
      "nvim-tree/nvim-tree.lua",
      cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("nvim-tree").setup({
          git = {
            enable = true,
            ignore = false,
          },
          update_focused_file = {
            enable = true,
            update_root = false,
          },
          renderer = {
            highlight_git = true,
            icons = {
              show = {
                git = true,
              },
            },
          },
        })
      end,
    },
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
    {
      "andythigpen/nvim-coverage",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("coverage").setup({
          commands = true,
          auto_reload = true,
          signs = {
            covered = { hl = "CoverageCovered", text = "▎" },
            uncovered = { hl = "CoverageUncovered", text = "▎" },
          },
          lang = {
            typescript = {
              coverage_file = "coverage/lcov.info",
            },
            javascript = {
              coverage_file = "coverage/lcov.info",
            },
          },
        })

        vim.api.nvim_create_autocmd({ "BufEnter" }, {
          callback = function()
            if vim.fn.filereadable("coverage/lcov.info") == 1 then
              vim.cmd("Coverage")
            end
          end,
        })
      end,
    },
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("gitsigns").setup({
          on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, lhs, rhs)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
            end

            map("n", "]h", gs.next_hunk)
            map("n", "[h", gs.prev_hunk)
            map("n", "<leader>hp", gs.preview_hunk)
            map("n", "<leader>hs", gs.stage_hunk)
            map("n", "<leader>hr", gs.reset_hunk)
            map("n", "<leader>hS", gs.stage_buffer)
            map("n", "<leader>hR", gs.reset_buffer)
            map("n", "<leader>hb", function()
              gs.blame_line({ full = true })
            end)
          end,
        })
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
  vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { silent = true })
  vim.keymap.set("n", "<leader>fe", "<cmd>NvimTreeFindFile<CR>", { silent = true })
end

return M
