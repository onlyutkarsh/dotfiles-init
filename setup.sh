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
            echo_message "permissions for $file_path are already $desired_permissions."
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
    echo_success "Git username set to: $username"

    # Set Git email
    git config --global user.email "$email"
    echo_success "Git email set to: $email"
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
    echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.zshrc
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

    # Test Homebrew installation
    brew doctor

    echo_success "Homebrew installed and configured."
else
    echo_message "Homebrew is already installed."
fi

if ! command -v chezmoi &>/dev/null; then
    brew install chezmoi
    echo_success "chezmoi installed."
else
    echo_message "chezmoi is already installed."
fi

# Check if Git is installed
if brew list --formula | grep -q "git"; then
    echo_message "git is already installed. updating..."
    # Update Git using Homebrew
    brew upgrade git
    echo_info "git updated using Homebrew."
else
    # Install Git using Homebrew
    brew install git
    echo_success "git installed using Homebrew."
fi

set_git_config "Utkarsh Shigihalli" "onlyutkarsh@users.noreply.github.com"

echo_success "All done!"
