Feature: Install script applies Zellij dotfiles
  As a dotfiles user
  I want install.sh to apply zellij files
  So zellij defaults are ready immediately

  Scenario: install.sh applies zellij config and default layout
    Given a temporary HOME for install testing
    When I run the dotfiles install script
    Then zellij install targets should exist in the temporary HOME
    And "~/.config/zellij/config.kdl" should contain the contents of "dot_config/zellij/config.kdl"
    And "~/.config/zellij/layouts/default.kdl" should contain the contents of "dot_config/zellij/layouts/default.kdl"
