Feature: Zellij palette auto-discovery option and argument builder loop
  Scenario: Action list is auto-discovered
    Given zellij and fzf are available for command execution
    When I run the zellij palette script with builder choice "Action: new-pane" and dry-run mode
    Then the discovered action list should include "Action: new-pane"
    And it should print "zellij action new-pane"

  Scenario: Option token discovery for selected action
    Given zellij is available for command execution
    When I inspect discovered option tokens for action "new-pane"
    Then it should include discovered option token "-d"
    And it should include discovered option token "--direction"

  Scenario: Multiple options added in one build dry-run
    Given zellij and fzf are available for command execution
    When I run builder dry-run for action "new-pane" with menu sequence
      | item                          |
      | Add option                    |
      | -f, --floating                |
      | Add option                    |
      | -n, --name <NAME>             |
      | Run command                   |
    And with input sequence
      | value |
      | pane1 |
    Then it should print "zellij action new-pane -f -n pane1"

  Scenario: Multiple args added in one build dry-run
    Given zellij and fzf are available for command execution
    When I run builder dry-run for action "new-pane" with menu sequence
      | item        |
      | Add argument |
      | <COMMAND>... |
      | Add argument |
      | <COMMAND>... |
      | Run command |
    And with input sequence
      | value |
      | echo  |
      | hello |
    Then it should print "zellij action new-pane echo hello"
    And it should include multiple argument values

  Scenario: Mixed options and args render options before positional args
    Given zellij and fzf are available for command execution
    When I run builder dry-run for action "new-pane" with menu sequence
      | item         |
      | Add option   |
      | -f, --floating |
      | Add argument |
      | <COMMAND>... |
      | Run command  |
    And with input sequence
      | value |
      | echo  |
    Then it should print "zellij action new-pane -f echo"
    And options should render before positional args

  Scenario: Duplicate non-repeatable option is prevented with replace or keep behavior
    Given zellij and fzf are available for command execution
    Then duplicate non-repeatable option handling should support keep and replace

  Scenario: Enum value selection path works
    Given zellij and fzf are available for command execution
    When I run builder dry-run for action "switch-mode" with menu sequence
      | item         |
      | Add argument |
      | <INPUT_MODE> |
      | session      |
      | Run command  |
    And I execute the prepared builder sequence
    Then it should print "zellij action switch-mode session"
    And enum value selection path should be used

  Scenario: Free-text value entry path works
    Given zellij and fzf are available for command execution
    When I run builder dry-run for action "new-pane" with menu sequence
      | item              |
      | Add option        |
      | -n, --name <NAME> |
      | Run command       |
    And with input sequence
      | value      |
      | named-pane |
    Then it should print "zellij action new-pane -n named-pane"
    And free-text value entry path should be used

  Scenario: Live execution path works with temporary session and cleanup
    Given zellij and fzf are available for command execution
    And a temporary zellij session exists for command execution
    When I run builder live execution for action "new-pane" with menu sequence
      | item                    |
      | Add option              |
      | -d, --direction <DIRECTION> |
      | right                   |
      | Run command             |
    Then the palette script command should succeed
    And temporary zellij session cleanup should succeed

  Scenario: Friendly wording regression excludes old typed text
    Given the repository zellij palette script
    Then old typed wording should not appear in palette script

  Scenario: Right-side hints are right-aligned in deterministic width
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with width 60
    Then rendered shortcut hints should be right-aligned

  Scenario: Direct modifier shortcut is shown when inferred
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with width 60
    Then action "new-pane" should show shortcut hint "Alt h"

  Scenario: Prefix chain is shown for mode-required action
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with width 60
    Then action "go-to-next-tab" should show shortcut hint "Ctrl t > down"

  Scenario: Action with no inferred mapping shows no hint
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with width 60
    Then action "launch-plugin" should show no shortcut hint

  Scenario: Hint display does not alter selection identity
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    Then hinted selection lines should keep action identity

  Scenario: Deterministic hinted rows use action spacer shortcut layout
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with width 60
    Then hinted rows should follow action spacer shortcut columns

  Scenario: Hints auto-align to detected inner content width
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines with detected columns 60
    Then rendered shortcut hints should be right-aligned to inner width 57
    And action "go-to-next-tab" should show shortcut hint "Ctrl t > down"

  Scenario: TTY width detection takes precedence over misleading COLUMNS
    Given zellij and fzf are available for command execution
    And deterministic palette bindings are configured
    When I list rendered palette lines in pseudo-tty with stty columns 60 and env columns 40
    Then rendered shortcut hints should be right-aligned to inner width 57
