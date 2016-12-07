echo "
[user]
  name = $GIT_USER_NAME
  email = $GIT_USER_EMAIL
[push]
  default = simple
[core]
	excludesfile = $HOME/.gitignore_global
  autocrlf = input
  safecrlf = true
  eol = lf
[filter \"lfs\"]
  required = true
  clean = git-lfs clean %f
  smudge = git-lfs smudge %f
[alias]
  # one-line log
  l = log --pretty=format:\"%C(yellow)%h\\\\\\\\ %ad%Cred%d\\\\\\\\ %Creset%s%Cblue\\\\\\\\ [%cn]\" --decorate --date=short

  a = add
  ap = add -p
  c = commit --verbose
  ca = commit -a --verbose
  cm = commit -m
  cam = commit -a -m
  m = commit --amend --verbose

  d = diff
  ds = diff --stat
  dc = diff --cached

  s = status -s
  co = checkout
  cob = checkout -b
  # list branches sorted by last modified
  b = \"!git for-each-ref --sort='-authordate' --format='%(authordate)%09%(objectname:short)%09%(refname)' refs/heads | sed -e 's-refs/heads/--'\"

  # list aliases
  la = \"!git config -l | grep alias | cut -c 7-\"
[commit]
	template = $HOME/.stCommitMsg
" > $HOME/.gitconfig
