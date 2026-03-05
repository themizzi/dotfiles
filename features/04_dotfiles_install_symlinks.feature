Feature: Install script links Vim-first dotfiles
  As a dotfiles user
  I want install.sh to create stable symlinks
  So setup is repeatable and idempotent

  Scenario: install.sh links vimrc and Neovim shim
    Given a temporary HOME for install testing
    When I run the dotfiles install script
    Then "~/.vimrc" should symlink to "vim/.vimrc"
    And "~/.config/nvim/init.vim" should symlink to "nvim/.config/nvim/init.vim"
    When I run the dotfiles install script
    Then "~/.vimrc" should symlink to "vim/.vimrc"
    And "~/.config/nvim/init.vim" should symlink to "nvim/.config/nvim/init.vim"
