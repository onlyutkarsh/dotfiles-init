#!/bin/bash

# Install Zsh if not already installed
if ! command -v zsh &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh
    chsh -s $(which zsh)
else
    echo "Zsh is already installed."
fi

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to Zsh configuration
    echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.zshrc
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

    # Test Homebrew installation
    brew doctor

    echo "Homebrew installed and configured."
else
    echo "Homebrew is already installed."
fi

echo "Zsh and Homebrew setup complete! Setting up SSH directory now..."

# Set up SSH directory if not already present
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
fi

# Configure SSH config file for GitHub and GitLab
cat <<EOF >>"$ssh_dir/config"

Host github.com
    HostName github.com
    IdentityFile $ssh_dir/id_ed25519_github

Host gitlab.com
    HostName gitlab.com
    IdentityFile $ssh_dir/id_ed25519_gitlab
EOF
chmod 600 "$ssh_dir/config"
echo "SSH config file configured."

# Function to copy and set permissions for SSH key files
set_permissions() {
    local key_name="$1"
    local key_path="$ssh_dir/$key_name"
    local pub_key_path="$ssh_dir/$key_path.pub"

    if [ -f "$key_path" ] && [ -f "$pub_key_path" ]; then
        chmod 600 "$ssh_dir/$key_name"
        chmod 644 "$ssh_dir/$key_name.pub"
        echo "$key_name and $key_name.pub permissions set."
    else
        echo "Error: $key_name or $key_name.pub not found at $key_path - Please copy them to $ssh_dir and run this script again."
    fi
}

# Copy and set permissions for GitHub SSH key
set_permissions "id_ed25519_github"

# Copy and set permissions for GitLab SSH key
set_permissions "id_ed25519_gitlab"

echo "SSH directory setup complete! Setting up Chezmoi now..."
if ! command -v chezmoi &>/dev/null; then
    brew install chezmoi
fi

echo "update git using brew"
# Check if Git is installed
if brew list --formula | grep -q "git"; then
    # Update Git using Homebrew
    brew upgrade git
    echo "Git updated using Homebrew."
else
    # Install Git using Homebrew
    brew install git
    echo "Git installed using Homebrew."
fi
