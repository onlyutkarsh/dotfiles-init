# Minimal bootstrap script for Windows
$ErrorActionPreference = "Stop"

function Write-Success { param([string]$msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Info { param([string]$msg) Write-Host "→ $msg" -ForegroundColor Cyan }
function Write-Warning { param([string]$msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }

Write-Info "Starting Windows bootstrap..."

# Install Scoop if not present
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Write-Success "Scoop installed"
} else {
    Write-Info "Scoop already installed"
}

# Install essential packages
Write-Info "Installing git, 1password-cli, and chezmoi..."
scoop install git 1password-cli chezmoi
Write-Success "Essential packages installed"

# Setup SSH directory
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -Path $sshDir -ItemType Directory | Out-Null
    Write-Success "Created ~/.ssh directory"
} else {
    Write-Info "~/.ssh directory already exists"
}

# Create SSH config
$configFile = "$sshDir\config"
if (-not (Test-Path $configFile)) {
    New-Item -Path $configFile -ItemType File | Out-Null
    Write-Success "Created SSH config file"
}

# Add GitHub entry
if (-not (Get-Content $configFile -ErrorAction SilentlyContinue | Select-String "Host github.com")) {
    Add-Content -Path $configFile -Value @"

Host github.com
    HostName github.com
    IdentityFile ~/.ssh/github.pub
"@
    Write-Success "Added GitHub to SSH config"
} else {
    Write-Info "GitHub already in SSH config"
}

# Add GitLab entry
if (-not (Get-Content $configFile -ErrorAction SilentlyContinue | Select-String "Host gitlab.com")) {
    Add-Content -Path $configFile -Value @"

Host gitlab.com
    HostName gitlab.com
    IdentityFile ~/.ssh/gitlab.pub
"@
    Write-Success "Added GitLab to SSH config"
} else {
    Write-Info "GitLab already in SSH config"
}

# Add Azure DevOps entry
if (-not (Get-Content $configFile -ErrorAction SilentlyContinue | Select-String "Host ssh.dev.azure.com")) {
    Add-Content -Path $configFile -Value @"

Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    IdentityFile ~/.ssh/ado.pub
"@
    Write-Success "Added Azure DevOps to SSH config"
} else {
    Write-Info "Azure DevOps already in SSH config"
}

# Alert user about SSH keys
Write-Host ""
Write-Warning "IMPORTANT: Copy your SSH PUBLIC keys from 1Password to ~/.ssh/"
Write-Info "Private keys stay in 1Password - only public keys are needed locally"
Write-Host "Required files:"
Write-Host "  - github.pub"
Write-Host "  - gitlab.pub"
Write-Host "  - ado.pub"
Write-Host ""
Read-Host "Press Enter after you've copied the public keys to continue"

# Set SSH key permissions
Write-Info "Setting SSH public key permissions..."
if (Test-Path "$sshDir\github.pub") {
    icacls "$sshDir\github.pub" /inheritance:r /grant:r "$($env:USERNAME):R" | Out-Null
    Write-Success "Set permissions for github.pub"
}
if (Test-Path "$sshDir\gitlab.pub") {
    icacls "$sshDir\gitlab.pub" /inheritance:r /grant:r "$($env:USERNAME):R" | Out-Null
    Write-Success "Set permissions for gitlab.pub"
}
if (Test-Path "$sshDir\ado.pub") {
    icacls "$sshDir\ado.pub" /inheritance:r /grant:r "$($env:USERNAME):R" | Out-Null
    Write-Success "Set permissions for ado.pub"
}

# Initialize chezmoi
Write-Host ""
Write-Info "Ready to initialize chezmoi!"
Write-Host "Run: chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git"
Write-Host ""
Write-Success "Bootstrap complete! Chezmoi will handle the rest."
