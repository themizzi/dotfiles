Feature: Open a file from netrw
  As a user of built-in netrw
  I want to open files from the explorer
  So that I can edit fixture files deterministically

  Scenario: Open alpha.txt from netrw with Enter
    Given an embedded Neovim session in the fixture workspace
    When I send normal keys "\<leader>e"
    And I move the netrw cursor to "alpha.txt"
    And I send normal keys "\<CR>"
    Then the current buffer path should end with "alpha.txt"
    And the current buffer should contain line "alpha fixture line"
