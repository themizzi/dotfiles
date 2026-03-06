Feature: Zsh syntax highlighting bootstrap
  As a user
  I want zsh plugins to load regardless of antidote install style
  So syntax highlighting works on macOS Homebrew setups

  Scenario: Homebrew antidote path is used when ~/.antidote is absent
    Given ~/.antidote/antidote.zsh does not exist
    And /opt/homebrew/opt/antidote/share/antidote/antidote.zsh exists
    When I start an interactive zsh session
    Then "_zsh_highlight" should be a defined function

  Scenario: Fallback antidote path works for non-Homebrew setups
    Given /opt/homebrew/opt/antidote/share/antidote/antidote.zsh does not exist
    And ~/.antidote/antidote.zsh exists
    When I start an interactive zsh session
    Then "_zsh_highlight" should be a defined function

  Scenario: Syntax-highlighting plugin remains last in plugin order
    Given the zsh plugin list file exists
    Then "zsh-users/zsh-syntax-highlighting" should be the last non-empty entry

  Scenario: Stale compiled zshrc does not mask new config
    Given ~/.zshrc.zwc exists
    When I refresh shell configuration
    Then runtime should reflect updated .zshrc plugin-loading logic
