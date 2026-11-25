local all = {}
local function collect(specs)
	for _, spec in ipairs(specs) do
		if type(spec) == "string" then
			spec = { spec }
		end
		assert(type(spec[1]) == "string")
		if spec.commit then
			assert(#spec.commit == 40)
		end
		if not all[spec[1]] or spec.opts or spec.lazy ~= nil then
			all[spec[1]] = spec
		end
		if spec.dependencies then
			collect(spec.dependencies)
		end
	end
end
collect(require("themizzi.plugins").specs())
for _, repo in ipairs({
	"folke/todo-comments.nvim",
	"andythigpen/nvim-coverage",
	"windwp/nvim-autopairs",
	"folke/flash.nvim",
	"lukas-reineke/indent-blankline.nvim",
	"saghen/blink.cmp",
	"rafamadriz/friendly-snippets",
	"nvim-treesitter/nvim-treesitter",
	"sindrets/diffview.nvim",
	"nickjvandyke/opencode.nvim",
	"folke/snacks.nvim",
	"catppuccin/nvim",
	"nvim-lualine/lualine.nvim",
	"MeanderingProgrammer/render-markdown.nvim",
}) do
	assert(all[repo], "Missing capability: " .. repo)
end
for _, repo in ipairs({
	"olimorris/codecompanion.nvim",
	"ravitemer/mcphub.nvim",
	"HakonHarnes/img-clip.nvim",
	"nvim-telescope/telescope.nvim",
	"nvim-tree/nvim-tree.lua",
}) do
	assert(not all[repo])
end
assert(not package.loaded["themizzi.plugins.ai"])
assert(all["saghen/blink.cmp"].opts.fuzzy.implementation == "lua")
local ts = all["nvim-treesitter/nvim-treesitter"]
assert(ts.branch == "main" and ts.build == nil and ts.lazy == false)
for _, key in ipairs({ "tn", "tp", "tl", "tq", "tf", "ts", "fe" }) do
	assert(vim.fn.maparg(" " .. key, "n") ~= "", "Missing mapping: " .. key)
end
