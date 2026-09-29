if filereadable(expand('~/.vimrc'))
  source ~/.vimrc
endif

lua << EOF
require("themizzi").setup()
EOF
