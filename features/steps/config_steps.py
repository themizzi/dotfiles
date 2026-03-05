from behave import then


@then('Vim expression "{expr}" should equal "{expected}"')
def step_vim_expr_equals(context, expr, expected):
    actual = context.nvim.request("nvim_eval", expr)
    assert actual == expected, f"Expected {expr}={expected!r}, got {actual!r}"


@then('Vim option "{option_name}" should be enabled')
def step_vim_option_enabled(context, option_name):
    actual = context.nvim.request("nvim_get_option_value", option_name, {})
    assert actual is True, f"Expected option {option_name} enabled, got {actual!r}"
