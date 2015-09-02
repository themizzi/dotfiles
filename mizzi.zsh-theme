# sorin.zsh-theme
# screenshot: http://i.imgur.com/aipDQ.png

if [[ "$TERM" != "dumb" ]] && [[ "$DISABLE_LS_COLORS" != "true" ]]; then
  MODE_INDICATOR="%{$fg_bold[red]%}❮%{$reset_color%}%{$fg[red]%}❮❮%{$reset_color%}"
  local return_status="%{$fg[red]%}%(?..⏎)%{$reset_color%}"
  
  PROMPT='%{$fg[yellow]%}%n@%M:%{$fg[cyan]%}%c$(git_prompt_info)$(svn_prompt_info) %(!.%{$fg_bold[red]%}#.%{$fg_bold[green]%}❯)%{$reset_color%} '

  ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}git%{$reset_color%}:%{$fg[red]%}"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_DIRTY=""
  ZSH_THEME_GIT_PROMPT_CLEAN=""

  ZSH_THEME_SVN_PROMPT_PREFIX=" %{$fg[blue]%}svn%{$reset_color%}:%{$fg[red]%}"
  ZSH_THEME_SVN_PROMPT_SUFFIX="%{$reset_color%}"

  RPROMPT='${return_status}$(git_prompt_status)$(svn_status_info)%{$reset_color%}'

  ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} ✚"
  ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} ✹"
  ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✖"
  ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} ➜"
  ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} ═"
  ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} ✭"

  ZSH_THEME_SVN_PROMPT_ADDITIONS="%{$fg[green]%} +"
  ZSH_THEME_SVN_PROMPT_DELETIONS="%{$fg[red]%} ✖"
  ZSH_THEME_SVN_PROMPT_MODIFICATIONS="%{$fg[blue]%} ✎"
  ZSH_THEME_SVN_PROMPT_REPLACEMENTS="%{$fg[magenta]%} ∿"
  ZSH_THEME_SVN_PROMPT_UNTRACKED="%{$fg[cyan]%} ?"
  ZSH_THEME_SVN_PROMPT_DIRTY="%{$fg[yellow]%} !"
else 
  MODE_INDICATOR="❮❮❮"
  local return_status="%(?::⏎)"
  
  PROMPT='%c$(git_prompt_info)$(svn_prompt_info) %(!.#.❯) '

  ZSH_THEME_GIT_PROMPT_PREFIX=" git:"
  ZSH_THEME_GIT_PROMPT_SUFFIX=""
  ZSH_THEME_GIT_PROMPT_DIRTY=""
  ZSH_THEME_GIT_PROMPT_CLEAN=""

  ZSH_THEME_SVN_PROMPT_PREFIX=" svn:"
  ZSH_THEME_SVN_PROMPT_SUFFIX=""

  RPROMPT='${return_status}$(git_prompt_status)$(svn_status_info)'

  ZSH_THEME_GIT_PROMPT_ADDED=" ✚"
  ZSH_THEME_GIT_PROMPT_MODIFIED=" ✹"
  ZSH_THEME_GIT_PROMPT_DELETED=" ✖"
  ZSH_THEME_GIT_PROMPT_RENAMED=" ➜"
  ZSH_THEME_GIT_PROMPT_UNMERGED=" ═"
  ZSH_THEME_GIT_PROMPT_UNTRACKED=" ✭"
fi
