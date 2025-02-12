#!/bin/bash

# colors
SUCCESS_COLOR="#2ECC71"
MESSAGE_COLOR="#A5D6FF"
WARNING_COLOR="#FFA500"
ERROR_COLOR="#FF0000"

# Function to copy and set permissions for SSH key files
set_permissions() {
    local file_path="$1"
    local desired_permissions="$2"

    # Check if the file exists
    if [ -e "$file_path" ]; then
        # Check current permissions
        if [[ $(uname) == "Linux" ]]; then
            current_permissions=$(stat -c%a "$file_path") 2>/dev/null
        elif [[ $(uname) == "Darwin" ]]; then
            current_permissions=$(stat -f%p "$file_path") 2>/dev/null || current_permissions=$(stat -f%Lp "$file_path")
        fi

        # Check if permissions are different from the desired value
        if [ "$current_permissions" != "$desired_permissions" ]; then
            # Set permissions to the desired value
            chmod "$desired_permissions" "$file_path"
            gum style --foreground "$SUCCESS_COLOR" "permissions for $file_path set to $desired_permissions."
        else
            gum style --foreground "$MESSAGE_COLOR" "permissions for $file_path is already $desired_permissions."
        fi
    else
        write_message "$file_path does not exist.", "warning"
    fi
}

set_git_config() {
    local username="$1"
    local email="$2"

    # Set Git username
    git config --global user.name "$username"
    gum style --foreground $SUCCESS_COLOR "git username set to: $username"

    # Set Git email
    git config --global user.email "$email"
    gum style --foreground $SUCCESS_COLOR "git email set to: $email"
}

write_message() {
    local message="$1"
    local type="$2"
    if command -v gum &>/dev/null; then
        case "$type" in
            "success")
                gum style --foreground $SUCCESS_COLOR "$message"
                ;;
            "message")
                gum style --foreground $MESSAGE_COLOR "$message"
                ;;
            "warning")
                gum style --foreground $WARNING_COLOR "$message"
                ;;
            "error")
                gum style --foreground $ERROR_COLOR "$message"
                ;;
            *)
                echo "$message"
                ;;
        esac
    else
        echo "$message"
    fi
}

# Install Zsh if not already installed
if [[ $(uname) == "Linux" ]]; then
    if ! command -v zsh &>/dev/null; then
        sudo apt update
        sudo apt install -y zsh
        chsh -s $(which zsh)
        write_message "zsh installed and configured.", "success"
    else
        write_message "zsh is already installed.", "message"
    fi
elif [[ $(uname) == "Darwin" ]]; then
    if ! command -v zsh &>/dev/null; then
        brew install zsh
        chsh -s $(which zsh)
        gum style --foreground $SUCCESS_COLOR "zsh installed and configured."
        write_message "zsh installed and configured.", "success"
    else
        write_message "zsh is already installed.", "message" 
    fi
fi

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to Zsh configuration
    if [[ $(uname) == "Linux" ]]; then
        echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.zshrc
        eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    elif [[ $(uname) == "Darwin" ]]; then
        echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>~/.zshrc
        eval $(/opt/homebrew/bin/brew shellenv)
    fi
    # Test Homebrew installation
    brew doctor

    write_message "Homebrew installed and configured.", "success"
else
    write_message "Homebrew is already installed.", "message"
fi

# download Brewfile from GitHub silently
if [ -d ~/.tmp ]; then
    rm -rf ~/.tmp
fi
mkdir -p ~/.tmp
curl -s -o ~/.tmp/Brewfile https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/Brewfile

# Install packages from Brewfile
brew bundle install --file=~/.tmp/Brewfile

# Set up SSH directory if not already present
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    gum style --foreground $SUCCESS_COLOR "~/.ssh directory created successfully."
else
    gum style --foreground $MESSAGE_COLOR "directory ~/.ssh already exists."
fi

# Configure SSH config file for GitHub and GitLab
# Check and append entries to SSH config file for GitHub and GitLab
config_file="$ssh_dir/config"

if ! grep -q "Host github.com" "$config_file"; then
    echo -e "\nHost github.com\n    HostName github.com\n    IdentityFile ~/.ssh/id_ed25519_github" >>"$config_file"
    gum style --foreground $SUCCESS_COLOR "GitHub entry added to $config_file."
else
    gum style --foreground $MESSAGE_COLOR "GitHub entry already exists in $config_file."
fi

if ! grep -q "Host gitlab.com" "$config_file"; then
    echo -e "\nHost gitlab.com\n    HostName gitlab.com\n    IdentityFile ~/.ssh/id_ed25519_gitlab" >>"$config_file"
    gum style --foreground $SUCCESS_COLOR "GitLab entry added to $config_file."
else
    gum style --foreground $MESSAGE_COLOR "GitLab entry already exists in $config_file."
fi

if ! grep -q "Host ssh.dev.azure.com" "$config_file"; then
    echo -e "\nHost ssh.dev.azure.com\n    HostName ssh.dev.azure.com\n    IdentityFile ~/.ssh/id_rsa_azuredevops" >>"$config_file"
    gum style --foreground $SUCCESS_COLOR "Azure DevOps entry added to $config_file."
else
    gum style --foreground $MESSAGE_COLOR "Azure DevOps entry already exists in $config_file."
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

# setup starship
gum style --foreground $MESSAGE_COLOR "Setting up starship prompt"
mkdir -p ~/.config
curl -s -o ~/.config/starship.toml https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/starship.toml
# add starship to zshrc if not already present
if ! grep -q "eval \"\$(starship init zsh)\"" ~/.zshrc; then
    # add new line and starship prompt to zshrc
    echo "\n" >>~/.zshrc
    echo 'eval "$(starship init zsh)"' >>~/.zshrc
    gum style --foreground $SUCCESS_COLOR "starship prompt setup successfully."
else
    gum style --foreground $MESSAGE_COLOR "starship prompt is already set up."
fi

# ask if user wants to set git username and email
gum confirm "Do you want to set your Git username and email?" || exit 0
GITHUB_USER=$(gum input --placeholder "Utkarsh Shigihalli" --value "$GITHUB_USER")
GITHUB_EMAIL=$(gum input --placeholder "onlyutkarsh@users.noreply.github.com" --value "$GITHUB_EMAIL")
set_git_config "$GITHUB_USER" "$GITHUB_EMAIL"

gum style --foreground $SUCCESS_COLOR "All done! - Run brew update if you want to update the tools."
exit 0
