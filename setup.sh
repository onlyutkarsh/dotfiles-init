#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_info() { echo -e "${BLUE}→ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Detect OS and WSL
OS="$(uname -s)"
IS_WSL=false
case "$OS" in
    Linux*)  PLATFORM="linux"
             if grep -qi microsoft /proc/version 2>/dev/null; then
                 IS_WSL=true
             fi
             ;;
    Darwin*) PLATFORM="macos";;
    *)       echo "Unsupported OS: $OS"; exit 1;;
esac

log_info "Detected platform: $PLATFORM"
if [ "$IS_WSL" = true ]; then
    log_info "Running inside WSL - SSH will be handled by Windows"
fi

# Install system dependencies on Linux/WSL
if [ "$PLATFORM" = "linux" ]; then
    log_info "Checking for required system packages..."
    
    # Check if unzip is installed
    if ! command -v unzip &>/dev/null; then
        log_info "Installing unzip (required by Homebrew)..."
        sudo apt-get update -qq
        sudo apt-get install -y unzip
        log_success "unzip installed"
    else
        log_info "unzip already installed"
    fi
    
    # Install other common dependencies for Homebrew on Linux
    if ! dpkg -s build-essential curl file git &>/dev/null 2>&1; then
        log_info "Installing build-essential and other dependencies..."
        sudo apt-get install -y build-essential curl file git
        log_success "Build dependencies installed"
    else
        log_info "Build dependencies already installed"
    fi
fi

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    for brew_path in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_path" ]; then
            eval "$("$brew_path" shellenv)"
            break
        fi
    done
fi
if ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    brew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    /bin/bash -c "$brew_installer"

    # Add to PATH
    if [ "$PLATFORM" = "linux" ]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        if [ -x /opt/homebrew/bin/brew ]; then
            brew_path=/opt/homebrew/bin/brew
        else
            brew_path=/usr/local/bin/brew
        fi
        printf 'eval "$(%s shellenv)"\n' "$brew_path" >> ~/.zprofile
        eval "$("$brew_path" shellenv)"
    fi
    log_success "Homebrew installed"
else
    log_info "Homebrew already installed"
fi

# Install essential packages
log_info "Installing git, 1password-cli, chezmoi, and zsh..."
brew install git 1password-cli chezmoi zsh
log_success "Essential packages installed"

# Set zsh as default shell
log_info "Configuring zsh as default shell..."
zsh_path="$(brew --prefix)/bin/zsh"
current_shell="$(basename "$SHELL")"

if [ "$current_shell" = "zsh" ]; then
    log_info "zsh is already the default shell"
else
    # Add zsh to allowed shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    
    log_info "Changing default shell to zsh..."
    chsh -s "$zsh_path"
    log_success "Default shell changed to zsh (restart terminal to take effect)"
fi

# Setup SSH directory
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    log_success "Created ~/.ssh directory"
else
    log_info "~/.ssh directory already exists"
fi

# Create .gitconfig with 1Password SSH agent configuration
log_info "Configuring .gitconfig for SSH..."
gitconfig_path="$HOME/.gitconfig"

if [ "$IS_WSL" = true ]; then
    expected_ssh_command="/mnt/c/WINDOWS/System32/OpenSSH/ssh.exe"
else
    expected_ssh_command=""
fi

if [ -f "$gitconfig_path" ]; then
    log_info ".gitconfig exists, verifying sshCommand..."
    if [ "$IS_WSL" = true ]; then
        current_ssh_command=$(git config --global core.sshCommand 2>/dev/null || true)
        if [ "$current_ssh_command" = "$expected_ssh_command" ]; then
            log_success "sshCommand already correctly set"
        else
            log_info "Updating sshCommand to use Windows OpenSSH..."
            git config --global core.sshCommand "$expected_ssh_command"
            log_success "Updated sshCommand for 1Password SSH agent"
        fi
    fi
else
    if [ "$IS_WSL" = true ]; then
        cat > "$gitconfig_path" << 'EOF'
[core]
	excludesfile = ~/.gitignore
	attributesfile = ~/.gitattributes
	autocrlf = input
	pager = delta
	sshCommand = /mnt/c/WINDOWS/System32/OpenSSH/ssh.exe
EOF
        log_success "Created .gitconfig for WSL with Windows SSH path"
    else
        cat > "$gitconfig_path" << 'EOF'
[core]
	excludesfile = ~/.gitignore
	attributesfile = ~/.gitattributes
	autocrlf = input
	pager = delta
EOF
        log_success "Created .gitconfig for native $PLATFORM"
    fi
    chmod 644 "$gitconfig_path"
fi

if [ "$IS_WSL" = true ]; then
    # On WSL, SSH is handled entirely by Windows native OpenSSH (ssh.exe).
    # The ssh command is aliased to /mnt/c/WINDOWS/System32/OpenSSH/ssh.exe
    # and git uses it via core.sshCommand. SSH keys and 1Password agent
    # are managed on the Windows side. No SSH config or pub files needed here.
    log_info "Skipping SSH config and key setup (handled by Windows)"
    echo ""
    log_warning "Run setup.ps1 on Windows first and enable the SSH agent in 1Password desktop."
else
    config_file="$ssh_dir/config"
    if [ "$PLATFORM" = "macos" ]; then
        agent_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
        agent_socket="$HOME/.1password/agent.sock"
    fi
    existing_config=""
    if [ -f "$config_file" ]; then
        existing_config="$(awk '
            /^# BEGIN dotfiles-init 1Password$/ { managed = 1; next }
            /^# END dotfiles-init 1Password$/ { managed = 0; next }
            managed { next }
            { print }
        ' "$config_file")"
    fi
    printf '# BEGIN dotfiles-init 1Password\nHost github.com\n    HostName github.com\n    User git\n    IdentityFile ~/.ssh/github.pub\n    IdentitiesOnly yes\n\nHost gitlab.com\n    HostName gitlab.com\n    IdentityFile ~/.ssh/gitlab.pub\n\nHost ssh.dev.azure.com vs-ssh.visualstudio.com\n    HostName ssh.dev.azure.com\n    IdentityFile ~/.ssh/ado.pub\n\nHost github.com gitlab.com ssh.dev.azure.com vs-ssh.visualstudio.com\n    IdentityAgent "%s"\n\nHost *\n# END dotfiles-init 1Password\n%s\n' "$agent_socket" "$existing_config" > "$config_file"
    chmod 700 "$ssh_dir"
    chmod 600 "$config_file"
    log_success "Configured SSH public-key selectors to match dotfiles"
    public_keys=(github.pub gitlab.pub ado.pub)
    missing_keys=false
    for public_key in "${public_keys[@]}"; do
        if [ ! -f "$ssh_dir/$public_key" ]; then
            log_warning "Missing $ssh_dir/$public_key"
            missing_keys=true
        fi
    done
    if [ "$missing_keys" = true ]; then
        log_warning "Download these PUBLIC keys from 1Password to $ssh_dir. Private keys stay in 1Password."
        read -r -p "Press Enter after downloading the public keys..."
    fi
    for public_key in "${public_keys[@]}"; do
        if ! ssh-keygen -lf "$ssh_dir/$public_key"; then
            log_warning "Missing or invalid public key: $ssh_dir/$public_key"
            exit 1
        fi
        chmod 644 "$ssh_dir/$public_key"
    done
fi

log_warning "Enable the SSH agent in 1Password desktop and unlock the app."
log_info "Register the matching public keys with your Git hosts. On WSL, public-key files belong on Windows only."

# Initialize chezmoi
echo ""
log_info "Ready to initialize chezmoi!"
echo "Run: chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git"
echo ""
log_success "Bootstrap complete! Chezmoi will handle the rest."
