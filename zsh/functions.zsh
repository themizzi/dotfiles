is_mac () {
	if test "$(uname)" = "Darwin"; then
		return 0
	else
		return 1
	fi
}

is_linux () {
	if test "$(expr substr $(uname -s) 1 5)" = "Linux"; then
		return 0
	else
		return 1
	fi
}
