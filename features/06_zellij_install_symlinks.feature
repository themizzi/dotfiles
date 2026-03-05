Feature: Install script links Zellij dotfiles
  As a dotfiles user
  I want install.sh to create zellij symlinks
  So zellij defaults are ready immediately

  Scenario: install.sh links zellij config and default layout
    Given a temporary HOME for install testing
    When I run the dotfiles install script
    Then zellij install targets should exist in the temporary HOME
    And "~/.config/zellij/config.kdl" should symlink to "zellij/.config/zellij/config.kdl"
    And "~/.config/zellij/layouts/default.kdl" should symlink to "zellij/.config/zellij/layouts/default.kdl"
