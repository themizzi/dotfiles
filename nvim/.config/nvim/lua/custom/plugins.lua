local plugins = {
    {
        "mfussenegger/nvim-dap",
        config = function()
            require("dap").configuration.lua = {}
        end
    },
    {
        "lewis6991/gitsigns.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        config = function()
            require("gitsigns").setup()
        end
    }
}

return plugins
