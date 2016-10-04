export EDITOR='atom --wait'
export PATH="$(brew --prefix)/bin:$(brew --prefix):/sbin:~/.rbenv/versions/2.2.2/bin/:$PATH"
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
fpath=(/usr/local/share/zsh-completions $fpath)
cdpath=(~/Documents ~/Dropbox $cdpath)
setopt promptsubst
