return {
  {
    "tpope/vim-sleuth",
  },
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        format_on_save = {
          lsp_fallback = true,
          timeout_ms = 500,
        },
        formatters_by_ft = {
          bash = { "shfmt" },
          go = { "gofmt" },
          javascript = { "prettierd", "prettier" },
          javascriptreact = { "prettierd", "prettier" },
          json = { "jq" },
          lua = { "stylua" },
          python = { "ruff_format", "black" },
          rust = { "rustfmt" },
          sh = { "shfmt" },
          typescript = { "prettierd", "prettier" },
          typescriptreact = { "prettierd", "prettier" },
          yaml = { "yq" },
        },
      })
    end,
  },
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("Comment").setup({})
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "TodoLocList", "TodoQuickFix", "TodoTelescope", "TodoFzfLua" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("todo-comments").setup({})
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
}
