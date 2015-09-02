# Modules
source "$HOME/.dotfiles/antigen/antigen.zsh"

antigen use oh-my-zsh

antigen bundle git
antigen bundle pip
antigen bundle rsync
antigen bundle python
antigen bundle zsh-users/zsh-completions src
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle history
antigen bundle tmux
antigen bundle vundle
antigen bundle themizzi/dotfiles better-svn

antigen-theme themizzi/dotfiles mizzi
antigen-apply

# Environment
#export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/MacGPG2/bin"
#export ANDROID_HOME=/Users/themizzi/Library/Android/sdk
#export PATH=$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH
#export HOMEBREW_CASK_OPTS="--appdir=/Applications"
#export EDITOR=/usr/local/bin/vim
#export VISUAL=/usr/local/bin/vim

#HELPDIR=/usr/local/share/zsh/help
fpath=(/usr/local/share/zsh-completions $fpath)

# Aliases
#alias cd:plat="cd ~/Dropbox/Gorilla/Projects/platinum"
#alias brew:up="brew update && brew upgrade"
#alias ls="ls --color=auto"

# Functions
man() {
    env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}
