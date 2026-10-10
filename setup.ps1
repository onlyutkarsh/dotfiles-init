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

$installedBuckets = (scoop bucket list).Name
if ($LASTEXITCODE -ne 0) {
    throw "Failed to list Scoop buckets (exit code $LASTEXITCODE)."
}
if ($installedBuckets -notcontains 'extras') {
    scoop bucket add extras
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to add the Scoop extras bucket (exit code $LASTEXITCODE)."
    }
}

# Install essential packages
Write-Info "Installing git, 1password-cli, chezmoi, and autohotkey..."
scoop install git 1password-cli chezmoi autohotkey
if ($LASTEXITCODE -ne 0) {
    throw "Failed to install essential packages (exit code $LASTEXITCODE)."
}
Write-Success "Essential packages installed"

# Setup SSH directory
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -Path $sshDir -ItemType Directory | Out-Null
    Write-Success "Created ~/.ssh directory"
} else {
    Write-Info "~/.ssh directory already exists"
}

$configFile = "$sshDir\config"
$existingConfig = if (Test-Path -LiteralPath $configFile) {
    [System.IO.File]::ReadAllText($configFile)
} else { '' }
$existingConfig = $existingConfig -replace '(?ms)^# BEGIN dotfiles-init 1Password\r?\n.*?^# END dotfiles-init 1Password\r?\n', ''
$agentConfig = @'
# BEGIN dotfiles-init 1Password
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github.pub
    IdentitiesOnly yes

Host gitlab.com
    HostName gitlab.com
    IdentityFile ~/.ssh/gitlab.pub

Host ssh.dev.azure.com vs-ssh.visualstudio.com
    HostName ssh.dev.azure.com
    IdentityFile ~/.ssh/ado.pub

Host *
# END dotfiles-init 1Password
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($configFile, "$agentConfig`n$existingConfig", $utf8)
Write-Success "Configured SSH public-key selectors to match dotfiles"

# Create .gitconfig with 1Password SSH agent configuration
Write-Info "Configuring .gitconfig for Windows SSH..."
$sshCommand = Join-Path $env:WINDIR 'System32/OpenSSH/ssh.exe'
if (-not (Test-Path -LiteralPath $sshCommand)) {
    throw "Install Windows OpenSSH Client from Optional Features, then rerun this script."
}
git config --global core.sshCommand ('"{0}"' -f ($sshCommand -replace '\\', '/'))
if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure Windows OpenSSH (exit code $LASTEXITCODE)."
}

Write-Host ""
Write-Warning "Enable the SSH agent in 1Password desktop and unlock the app."
Write-Info "Register the matching public keys with your Git hosts. Private keys stay in 1Password."

$publicKeys = @('github.pub', 'gitlab.pub', 'ado.pub')
$missingKeys = @($publicKeys | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $sshDir $_) -PathType Leaf)
})
if ($missingKeys.Count -gt 0) {
    Write-Warning "Download these PUBLIC keys from 1Password to ${sshDir}: $($missingKeys -join ', ')"
    Read-Host "Press Enter after downloading the public keys"
}
$sshKeygen = Join-Path $env:WINDIR 'System32/OpenSSH/ssh-keygen.exe'
foreach ($publicKey in $publicKeys) {
    $keyPath = Join-Path $sshDir $publicKey
    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
        throw "Missing public key: $keyPath"
    }
    & $sshKeygen -lf $keyPath
    if ($LASTEXITCODE -ne 0) {
        throw "Invalid public key: $keyPath. Download the Public key directly from 1Password."
    }
}

Write-Info "Setting SSH permissions..."
icacls $sshDir /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to set SSH directory permissions (exit code $LASTEXITCODE)."
}
if (Test-Path $configFile) {
    icacls $configFile /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set SSH config permissions (exit code $LASTEXITCODE)."
    }
    Write-Success "Set permissions for config (owner only)"
}

# Initialize chezmoi
Write-Host ""
Write-Info "Ready to initialize chezmoi!"
Write-Host "Run: chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git"
Write-Host ""
Write-Success "Bootstrap complete! Chezmoi will handle the rest."
