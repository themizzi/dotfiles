return {
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
}
