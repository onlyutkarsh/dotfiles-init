#!/bin/bash

# Install Zsh
sudo apt update
sudo apt install -y zsh

# Set Zsh as the default shell
chsh -s $(which zsh)

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to Zsh configuration
echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.zshrc
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Test Homebrew installation
brew doctor

echo "Zsh and Homebrew setup complete!"
