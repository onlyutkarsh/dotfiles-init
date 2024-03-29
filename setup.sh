#!/bin/bash

# Function to echo an error message in red
echo_error() {
    echo -e "\e[91mError: $1\e[0m" >&2
}

# Function to echo a warning message in yellow
echo_warning() {
    echo -e "\e[93mWarning: $1\e[0m" >&2
}

# Function to echo a success message in green
echo_success() {
    echo -e "\e[32m$1\e[0m"
}

# Function to echo an info message in blue
echo_info() {
    echo -e "\e[36m$1\e[0m"
}

echo_message() {
    echo -e "\e[90m$1\e[0m"
}

# Function to copy and set permissions for SSH key files
set_permissions() {
    local file_path="$1"
    local desired_permissions="$2"

    # Check if the file exists
    if [ -e "$file_path" ]; then
        # Check current permissions
        current_permissions=$(stat -c "%a" "$file_path")

        # Check if permissions are different from the desired value
        if [ "$current_permissions" != "$desired_permissions" ]; then
            # Set permissions to the desired value
            chmod "$desired_permissions" "$file_path"
            echo_success "permissions for $file_path set to $desired_permissions."
        else
            echo_message "permissions for $file_path is already $desired_permissions."
        fi
    else
        echo_warning "$file_path does not exist."
    fi
}

set_git_config() {
    local username="$1"
    local email="$2"

    # Set Git username
    git config --global user.name "$username"
    echo_success "git username set to: $username"

    # Set Git email
    git config --global user.email "$email"
    echo_success "git email set to: $email"
}

# Set up SSH directory if not already present
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    echo_success "~/.ssh directory created."
else
    echo_message "directory ~/.ssh already exists."
fi

# Configure SSH config file for GitHub and GitLab
# Check and append entries to SSH config file for GitHub and GitLab
config_file="$ssh_dir/config"

if ! grep -q "Host github.com" "$config_file"; then
    echo -e "\nHost github.com\n    HostName github.com\n    IdentityFile ~/.ssh/id_ed25519_github" >>"$config_file"
    echo_success "GitHub entry added to $config_file."
else
    echo_message "GitHub entry already exists in $config_file."
fi

if ! grep -q "Host gitlab.com" "$config_file"; then
    echo -e "\nHost gitlab.com\n    HostName gitlab.com\n    IdentityFile ~/.ssh/id_ed25519_gitlab" >>"$config_file"
    echo_success "GitLab entry added to $config_file."
else
    echo_message "GitLab entry already exists in $config_file."
fi

if ! grep -q "Host ssh.dev.azure.com" "$config_file"; then
    echo -e "\nHost ssh.dev.azure.com\n    HostName ssh.dev.azure.com\n    IdentityFile ~/.ssh/id_rsa_azuredevops" >>"$config_file"
    echo_success "Azure DevOps entry added to $config_file."
else
    echo_message "Azure DevOps entry already exists in $config_file."
fi

set_permissions "$config_file" 600

# Copy and set permissions for GitHub SSH key
set_permissions "$ssh_dir/id_ed25519_github" 600
set_permissions "$ssh_dir/id_ed25519_github.pub" 644

# Copy and set permissions for GitLab SSH key
set_permissions "$ssh_dir/id_ed25519_gitlab" 600
set_permissions "$ssh_dir/id_ed25519_gitlab.pub" 644

# Copy and set permissions for Azure DevOps SSH key
set_permissions "$ssh_dir/id_rsa_azuredevops" 600
set_permissions "$ssh_dir/id_rsa_azuredevops.pub" 644

# Install Zsh if not already installed
if ! command -v zsh &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh
    chsh -s $(which zsh)
    echo_success "zsh installed and configured."
else
    echo_message "zsh is already installed."
fi

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to Zsh configuration
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.zshrc
        eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>~/.zshrc
        eval $(/opt/homebrew/bin/brew shellenv)
    fi
    # Test Homebrew installation
    brew doctor

    echo_success "Homebrew installed and configured."
else
    echo_message "Homebrew is already installed."
fi

# download Brewfile from GitHub silently
mkdir -p ~/.tmp
curl -s -o ~/.tmp/Brewfile https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/Brewfile

# Install packages from Brewfile
brew bundle install --file=~/.tmp/Brewfile

# setup starship
echo_info "Setting up starship prompt"
mkdir -p ~/.config
curl -s -o ~/.config/starship.toml https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/starship.toml
# add starship to zshrc if not already present
if ! grep -q "eval \"\$(starship init zsh)\"" ~/.zshrc; then
    # add new line and starship prompt to zshrc
    echo "\n" >>~/.zshrc
    echo 'eval "$(starship init zsh)"' >>~/.zshrc
    echo_success "starship prompt setup successfully."
else
    echo_message "starship prompt is already set up."
fi

# ask if user wants to set git username and email
echo_info "Do you want to set your git username and email?"
read -p "Enter y/n: " set_git_config
if [ "$set_git_config" == "y" ]; then
    # take username and email from user
    echo_info "Enter your git user name and email"
    read -p "Enter your Git username: " username
    read -p "Enter your Git email (e.g: username@users.noreply.github.com):" email
    set_git_config "$username" "$email"
    exit 0
else
    echo_success "All done! - Run brew update if you want to update the tools."
    exit 0
fi


