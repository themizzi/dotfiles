git_branch() {
	ref=`git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'}` || return 0
	if [ -n "$ref" ]
	then
		echo " $ref"
	fi
}
