Feature: Boot with shared Vim configuration
  As a Vim-first user
  I want Neovim to load ~/.vimrc through the Neovim shim
  So that one minimal configuration drives both editors

  Scenario: Embedded Neovim loads shared defaults
    Given an embedded Neovim session
    Then Vim expression "mapleader" should equal " "
    And Vim option "number" should be enabled
    And Vim option "hidden" should be enabled
