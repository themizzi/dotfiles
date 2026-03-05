Feature: Zellij minimal workflow is configured
  As a terminal multiplexer user
  I want practical defaults for panes and sessions
  So I can start using zellij immediately

  Scenario: zellij config defines pane/session essentials
    Given the repository zellij config
    Then it should include bindings for pane split and pane focus movement
    And it should include a session workflow binding

  Scenario: default layout is present and usable
    Given the repository zellij default layout
    Then it should define multiple panes

  Scenario: zellij binary is available in configured environments
    Given required runtime dependencies are installed
    Then "zellij" should be discoverable in PATH

  Scenario: zellij launch and session commands run successfully
    Given zellij is available for command execution
    When I run the zellij version command
    And I run a zellij session listing command
    Then the zellij version command should succeed
    And the zellij session listing command should succeed
