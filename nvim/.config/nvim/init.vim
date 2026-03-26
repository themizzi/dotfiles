if filereadable(expand('~/.vimrc'))
  source ~/.vimrc
endif

lua << EOF
local config_dir = vim.fn.stdpath("config")
local ok, plugins = pcall(dofile, config_dir .. "/lua/dotfiles/plugins.lua")
if ok and plugins then
  plugins.setup()
end
EOF
