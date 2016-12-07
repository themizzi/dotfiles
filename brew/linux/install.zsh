BREW=$(which brew)
if [ -z "$BREW" ]; then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
fi

sudo apt-get install -y build-essential

echo "Adding $HOME/.linuxbrew/bin to path"
export PATH="$HOME/.linuxbrew/bin:$PATH"

brew install grc
brew install z
brew cleanup -e
