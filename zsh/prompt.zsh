autoload -U colors && colors
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  host_color=$fg[blue]
else
  host_color=$fg[yellow]
fi
export PROMPT="%{$fg_bold[green]%}%n%{$reset_color%}%{$fg_bold[cyan]%}@%{$reset_color%}%{$host_color%}%M:%{$fg[cyan]%}%c%{$fg[red]%}\$(git_branch) %{$fg_bold[green]%}❯%{$reset_color%} "
setopt promptsubst
