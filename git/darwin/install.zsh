echo "[difftool \"sourcetree\"]
	cmd = opendiff \"\$LOCAL\" \"\$REMOTE\"
	path =
[mergetool \"sourcetree\"]
	cmd = /Applications/SourceTree.app/Contents/Resources/opendiff-w.sh \"\$LOCAL\" \"\$REMOTE\" -ancestor \"\$BASE\" -merge \"\y$MERGED\"
	trustExitCode = true
[credential]
  helper = osxkeychain
" >> $HOME/.gitconfig
