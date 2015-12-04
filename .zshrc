# Get the path of this file
source ~/.dotfiles_path

# Source all .zsh files
for D in  `find $DOTFILES_PATH -maxdepth 1 -type d ! -name ".*" | sort`
do
  for F in `find $D -maxdepth 1 -type f -name "*.zsh" | sort`
  do
    source $F
  done
done
