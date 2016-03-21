autoload -U colors && colors
export PROMPT="%{$fg_bold[green]%}%n%{$reset_color%}%{$fg_bold[cyan]%}@%{$reset_color%}%{$fg[yellow]%}%M:%{$fg[cyan]%}%c%{$fg[red]%}$(git_branch) %{$fg_bold[green]%}❯%{$reset_color%} "
