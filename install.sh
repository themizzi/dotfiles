function symysym {
	printf "$1"
	if [[ -e ~/$1 ]]; then
		if [[ -L ~/$1 ]]; then
			printf '\tlink already exists. skipping.\n';
			return
		fi
	fi
	ln -s ~/.dotfiles/$1 ~/$1
	printf '\tlinked\n';
}

symysym .zshrc
symysym .tmux.conf