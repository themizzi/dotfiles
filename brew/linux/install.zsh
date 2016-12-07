if [ -z $(which brew) ]; then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
fi

sudo apt-get install -y build-essential

brew install grc
brew install z
brew cleanup -e
