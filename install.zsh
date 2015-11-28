# Get the path of this file
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Write the path of this file
echo export DOTFILES_PATH=$DIR > ~/.dotfiles_path

# Link the .zshrc file
ln -s $DIR/.zshrc ~/.zshrc
