#!/usr/bin/env bats
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'helpers/editor.bash'

setup() { editor_fixture; }

@test "offline startup keeps defaults, mappings, and plugin bootstrap disabled" {
    run_editor_lua defaults.lua
    assert_success "$output"
}

@test "netrw toggles, opens a file, and preserves fixture contents" {
    run_editor_lua netrw.lua
    assert_success "$output"
}

@test "native OSC52 fallback remains available without system clipboard tools" {
    run_editor_lua clipboard.lua
    assert_success "$output"
}

@test "built-in picker and search fallbacks work with fixture files" {
    run_editor_lua pickers.lua
    assert_success "$output"
}

@test "Snacks mappings dispatch to expected picker functions" {
    run_editor_lua telescope-dispatch.lua
    assert_success "$output"
}

@test "all plugin capabilities are locked and replaced plugins are absent" {
    run_editor_lua plugins.lua
    assert_success "$output"
}

@test "project dashboard scopes actions and handles non-Git projects" {
    run_editor_lua dashboard.lua
    assert_success "$output"
}

@test "project, UI, Git and OpenCode features dispatch safely" {
    run_editor_lua features.lua
    assert_success "$output"
}

@test "TODO mappings preserve plugin dispatch and search fallback" {
    run_editor_lua todos.lua
    assert_success "$output"
}

@test "Treesitter preserves indentation without a supported query" {
    run_editor_lua treesitter.lua
    assert_success "$output"
}

@test "language servers use completion capabilities and offline completion" {
    run_editor_lua lsp.lua
    assert_success "$output"
}

@test "locked plugin specs and formatter alternatives remain valid" {
    run_editor_lua formatters.lua
    assert_success "$output"
}
