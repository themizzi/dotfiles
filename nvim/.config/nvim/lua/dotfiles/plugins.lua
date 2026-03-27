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
      "folke/which-key.nvim",
      event = "VeryLazy",
      config = function()
        require("which-key").setup({})
      end,
    },
    {
      "folke/tokyonight.nvim",
      priority = 1000,
      config = function()
        vim.opt.termguicolors = true
        vim.cmd.colorscheme("tokyonight")
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        local ok, treesitter = pcall(require, "nvim-treesitter.configs")
        if not ok then
          return
        end

        treesitter.setup({
          ensure_installed = { "bash", "css", "html", "javascript", "json", "lua", "python", "regex", "rust", "toml", "tsx", "typescript", "vim", "yaml" },
          highlight = { enable = true },
          indent = { enable = true },
        })
      end,
    },
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

        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or client.name ~= "pyright" then
              return
            end

            if client.supports_method("textDocument/semanticTokens/full") then
              pcall(vim.lsp.semantic_tokens.enable, args.buf, client.id)
            end
          end,
        })
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

            local function map(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
            end

            map("n", "]h", gs.next_hunk, "Next hunk")
            map("n", "[h", gs.prev_hunk, "Previous hunk")
            map("n", "<leader>gh", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
            map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
            map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
            map("n", "<leader>gb", function()
              gs.blame_line({ full = true })
            end, "Blame line")
          end,
        })
      end,
    },
    {
      "ojroques/nvim-osc52",
      config = function()
        local function copy(lines, _)
          require("osc52").copy(table.concat(lines, "\n"))
        end

        local function paste()
          return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
        end

        vim.g.clipboard = {
          name = "osc52",
          copy = {
            ["+"] = copy,
            ["*"] = copy,
          },
          paste = {
            ["+"] = paste,
            ["*"] = paste,
          },
        }

        vim.opt.clipboard = "unnamedplus"
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

  local ok, which_key = pcall(require, "which-key")
  if ok then
    which_key.add({
      { "<leader>f", group = "FZF" },
      { "<leader>g", group = "Git" },
    })
  end

  vim.keymap.set("n", "<leader>ff", invoke_picker("files"), { silent = true, desc = "Files" })
  vim.keymap.set("n", "<leader>fb", invoke_picker("buffers"), { silent = true, desc = "Buffers" })
  vim.keymap.set("n", "<leader>fc", invoke_picker("commands"), { silent = true, desc = "Commands" })
  vim.keymap.set("n", "<leader>fg", live_grep_or_fallback, { silent = true, desc = "Live grep" })
  vim.keymap.set("n", "<leader>fh", invoke_picker("helptags"), { silent = true, desc = "Help tags" })
  vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { silent = true, desc = "Explorer" })
  vim.keymap.set("n", "<leader>fe", "<cmd>NvimTreeFindFile<CR>", { silent = true, desc = "Find file in tree" })
end

return M
