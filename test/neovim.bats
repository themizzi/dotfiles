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

@test "fzf mappings dispatch to the expected picker functions" {
    run_editor_lua fzf-dispatch.lua
    assert_success "$output"
}

@test "all plugin capabilities are locked and AI is disabled by default" {
    run_editor_lua plugins.lua
    assert_success "$output"
}

@test "AI opt-in declares locked providers but remains offline without plugins" {
    run_editor_lua ai.lua
    assert_success "$output"
}

@test "TODO mappings preserve plugin dispatch and search fallback" {
    run_editor_lua todos.lua
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
