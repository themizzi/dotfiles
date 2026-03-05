Feature: Zellij command palette is configured
  Scenario: zellij config binds alt-space to open command palette
    Given the repository zellij config
    Then it should include the exact zellij command palette keybinding syntax
