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

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH
    if [ "$PLATFORM" = "linux" ]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
else
    log_info "Homebrew already installed"
fi

# Install essential packages
log_info "Installing git, 1password-cli, and chezmoi..."
brew install git 1password-cli chezmoi
log_success "Essential packages installed"

# Setup SSH directory
ssh_dir="$HOME/.ssh"
if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    log_success "Created ~/.ssh directory"
else
    log_info "~/.ssh directory already exists"
fi

if [ "$IS_WSL" = true ]; then
    # On WSL, SSH is handled entirely by Windows native OpenSSH (ssh.exe).
    # The ssh command is aliased to /mnt/c/WINDOWS/System32/OpenSSH/ssh.exe
    # and git uses it via core.sshCommand. SSH keys and 1Password agent
    # are managed on the Windows side. No SSH config or pub files needed here.
    log_info "Skipping SSH config and key setup (handled by Windows)"
    echo ""
    log_warning "Make sure you have run setup.ps1 on Windows first to set up SSH keys and config."
else
    # Create SSH config
    config_file="$ssh_dir/config"
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
        chmod 600 "$config_file"
        log_success "Created SSH config file"
    fi

    # Add GitHub entry
    if ! grep -q "Host github.com" "$config_file" 2>/dev/null; then
        cat >> "$config_file" << 'EOF'

Host github.com
    HostName github.com
    IdentityFile ~/.ssh/github.pub
EOF
        log_success "Added GitHub to SSH config"
    else
        log_info "GitHub already in SSH config"
    fi

    # Add GitLab entry
    if ! grep -q "Host gitlab.com" "$config_file" 2>/dev/null; then
        cat >> "$config_file" << 'EOF'

Host gitlab.com
    HostName gitlab.com
    IdentityFile ~/.ssh/gitlab.pub
EOF
        log_success "Added GitLab to SSH config"
    else
        log_info "GitLab already in SSH config"
    fi

    # Add Azure DevOps entry
    if ! grep -q "Host ssh.dev.azure.com" "$config_file" 2>/dev/null; then
        cat >> "$config_file" << 'EOF'

Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    IdentityFile ~/.ssh/ado.pub
EOF
        log_success "Added Azure DevOps to SSH config"
    else
        log_info "Azure DevOps already in SSH config"
    fi

    # SSH key status check helper
    ssh_pub_files=("github.pub" "gitlab.pub" "ado.pub")

    show_ssh_status() {
        for key in "${ssh_pub_files[@]}"; do
            if [ -f "$ssh_dir/$key" ]; then
                log_success "$key exists"
            else
                log_warning "$key MISSING"
            fi
        done
    }

    # Alert user about SSH keys
    echo ""
    log_warning "IMPORTANT: Copy your SSH PUBLIC keys from 1Password to ~/.ssh/"
    log_info "Private keys stay in 1Password - only public keys are needed locally"
    echo ""
    log_info "Current SSH key status:"
    show_ssh_status
    echo ""
    read -p "Press Enter after you've copied the public keys to continue..."

    # Show updated status and set permissions
    echo ""
    log_info "SSH key status:"
    show_ssh_status
    echo ""

    log_info "Setting SSH permissions..."
    chmod 700 "$ssh_dir"
    [ -f "$ssh_dir/config" ] && chmod 600 "$ssh_dir/config" && log_success "Set permissions for config (600)"
    for key in "${ssh_pub_files[@]}"; do
        if [ -f "$ssh_dir/$key" ]; then
            chmod 644 "$ssh_dir/$key"
            log_success "Set permissions for $key (644)"
        fi
    done
fi

# Initialize chezmoi
echo ""
log_info "Ready to initialize chezmoi!"
echo "Run: chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git"
echo ""
log_success "Bootstrap complete! Chezmoi will handle the rest."
