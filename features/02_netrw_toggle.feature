Feature: Toggle netrw explorer
  As a keyboard-driven user
  I want a leader mapping to toggle netrw
  So I can browse files without plugins

  Scenario: Leader e toggles netrw open and closed
    Given an embedded Neovim session in the fixture workspace
    And the active buffer is not netrw
    When I send normal keys "\<leader>e"
    Then a netrw buffer should be visible
    When I send normal keys "\<leader>e"
    Then no netrw buffer should be visible
