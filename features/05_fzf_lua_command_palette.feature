Feature: Neovim command palette with fzf-lua
  As a Neovim user
  I want leader mappings to open palette pickers
  So I can navigate files, buffers, commands, and help quickly

  Scenario: Open file picker from leader mapping
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    When I send normal keys "\<leader>p"
    Then the fzf-lua files picker should be active

  Scenario: Open buffer picker from leader mapping
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    And multiple buffers are open
    When I send normal keys "\<leader>b"
    Then the fzf-lua buffers picker should be active

  Scenario: Open command picker from leader mapping
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    When I send normal keys "\<leader>c"
    Then the fzf-lua commands picker should be active

  Scenario: Open help tags picker from leader mapping
    Given an embedded Neovim session in the fixture workspace
    And fzf-lua picker calls are captured
    When I send normal keys "\<leader>h"
    Then the fzf-lua helptags picker should be active
