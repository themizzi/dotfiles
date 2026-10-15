local M = {}

-- Install only via explicit setup opt-in or :TSInstall, never on buffer open.
M.parsers = {
	"bash",
	"css",
	"go",
	"html",
	"javascript",
	"json",
	"lua",
	"python",
	"regex",
	"rust",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"yaml",
	"markdown",
	"markdown_inline",
	"vimdoc",
}

M.opts = {
	ensure_installed = {},
	auto_install = false,
	highlight = { enable = true },
	indent = { enable = true },
}

return M
