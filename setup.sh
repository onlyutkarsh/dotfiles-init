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

# Function to copy and set permissions for SSH key files
set_permissions() {
    local key_name="$1"
    local key_path="$ssh_dir/$key_name"
    local pub_key_path="$ssh_dir/$key_name.pub"

    if [ -f "$key_path" ]; then
        chmod 600 "$key_path"
        echo_success "$key_path permissions set."
    else
        echo_warning "$key_name not found at $key_path - Please copy it to $ssh_dir and run this script again."
    fi

    if [ -f "$pub_key_path" ]; then
        chmod 644 "$pub_key_path"
        echo_success "$pub_key_path permissions set."
    else
        echo_warning "$key_name.pub not found at $pub_key_path - Please copy it to $ssh_dir and run this script again."
    fi
}

# Install Zsh if not already installed
if ! command -v zsh &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh
    chsh -s $(which zsh)
    echo_success "Zsh installed and configured."
else
    echo_info "Zsh is already installed."
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
    echo_info "Homebrew is already installed."
fi

echo "Zsh and Homebrew setup complete! Setting up SSH directory now..."

# Set up SSH directory if not already present
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    echo_success "SSH directory created."
else
    echo_info "SSH directory already exists."
fi

# Configure SSH config file for GitHub and GitLab
# Check and append entries to SSH config file for GitHub and GitLab
config_file="$ssh_dir/config"

if ! grep -q "Host github.com" "$config_file"; then
    echo -e "\nHost github.com\n    HostName github.com\n    IdentityFile ~/.ssh/id_ed25519_github" >>"$config_file"
    echo_success "GitHub entry added to $config_file."
else
    echo_info "GitHub entry already exists in $config_file."
fi

if ! grep -q "Host gitlab.com" "$config_file"; then
    echo -e "\nHost gitlab.com\n    HostName gitlab.com\n    IdentityFile ~/.ssh/id_ed25519_gitlab" >>"$config_file"
    echo_success "GitLab entry added to $config_file."
else
    echo_info "GitLab entry already exists in $config_file."
fi

if ! grep -q "Host ssh.dev.azure.com" "$config_file"; then
    echo -e "\nHost ssh.dev.azure.com\n    HostName ssh.dev.azure.com\n    IdentityFile ~/.ssh/id_rsa_azuredevops" >>"$config_file"
    echo_success "Azure DevOps entry added to $config_file."
else
    echo_info "Azure DevOps entry already exists in $config_file."
fi

chmod 600 "$config_file"
echo_success "SSH config file configured and permissions set."

# Copy and set permissions for GitHub SSH key
set_permissions "id_ed25519_github"

# Copy and set permissions for GitLab SSH key
set_permissions "id_ed25519_gitlab"

# Copy and set permissions for Azure DevOps SSH key
set_permissions "id_rsa_azuredevops"

echo "SSH directory setup complete! Setting up Chezmoi now..."
if ! command -v chezmoi &>/dev/null; then
    brew install chezmoi
    echo_success "chezmoi installed."
else
    echo_info "chezmoi is already installed."
fi

echo "update git using brew"
# Check if Git is installed
if brew list --formula | grep -q "git"; then
    # Update Git using Homebrew
    brew upgrade git
    echo_success "Git updated using Homebrew."
else
    # Install Git using Homebrew
    brew install git
    echo_success "Git installed using Homebrew."
fi

echo_success "All done!"
