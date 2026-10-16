if vim.fn.has("mac") == 1 then
	return
end
vim.env.PATH = "/nonexistent"
vim.env.DISPLAY, vim.env.WAYLAND_DISPLAY, vim.env.TMUX = nil, nil, nil
vim.g.termfeatures = { osc52 = true }
assert(vim.fn["provider#clipboard#Executable"]() == "OSC 52")
assert(vim.g.clipboard == nil)
