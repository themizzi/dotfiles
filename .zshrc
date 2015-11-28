# Get the path of this file
source ./.dotfiles_path

# Source all .zsh files
for D in  `find $DOTFILES_PATH -type d ! -name ".*" -maxdepth 1`
do
  for F in `find $D -type f -name "*.zsh" -maxdepth 1`
  do
    source $F
  done
done
