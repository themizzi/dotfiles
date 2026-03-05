if filereadable(expand('~/.vimrc'))
  source ~/.vimrc
endif

lua << EOF
require("dotfiles.fzf").setup()
EOF
