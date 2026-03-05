Feature: Grep workflow and fallback behavior
  As a Neovim user
  I want live grep on leader g with a safe fallback
  So search works across environments

  Scenario: Live grep uses ripgrep when available
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    And ripgrep is installed
    When I send normal keys "\<leader>g"
    Then the fzf-lua live grep picker should be active

  Scenario: Grep mapping fails gracefully without ripgrep
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    And ripgrep is not installed
    When I send normal keys "\<leader>g"
    Then Neovim should not error fatally
    And a configured fallback search behavior should be used
