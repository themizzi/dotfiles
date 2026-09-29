Feature: Install script applies Vim-first dotfiles
  As a dotfiles user
  I want install.sh to apply managed files
  So setup is repeatable and portable

  Scenario: install.sh applies vimrc and Neovim shim
    Given a temporary HOME for install testing
    When I run the dotfiles install script
    Then "~/.vimrc" should contain the contents of "dot_vimrc"
    And "~/.config/nvim/init.vim" should contain the contents of "dot_config/nvim/init.vim"
    When I run the dotfiles install script
    Then "~/.vimrc" should contain the contents of "dot_vimrc"
    And "~/.config/nvim/init.vim" should contain the contents of "dot_config/nvim/init.vim"
