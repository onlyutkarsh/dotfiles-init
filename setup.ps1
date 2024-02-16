# Function to write an error message in red
function Write-ErrorMsg {
    param([string]$msg)
    Write-Host "Error: $msg" -ForegroundColor Red
}

# Function to write a warning message in yellow
function Write-WarningMsg {
    param([string]$msg)
    Write-Host "Warning: $msg" -ForegroundColor Yellow
}

# Function to write a success message in green
function Write-SuccessMsg {
    param([string]$msg)
    Write-Host $msg -ForegroundColor Green
}

# Function to write an info message in blue
function Write-InfoMsg {
    param([string]$msg)
    Write-Host $msg -ForegroundColor Cyan
}

function Write-Message {
    param([string]$msg)
    Write-Host $msg -ForegroundColor DarkGray
}

# Function to copy and set permissions for SSH key files
function Check-Path {
    param(
        [string]$filePath
    )
    # error if file does not exist
    if (-Not (Test-Path $filePath)) {
        Write-WarningMsg "$filePath does not exist."
    }
}

function Set-GitConfig {
    param(
        [string]$username,
        [string]$email
    )

    # Set Git username
    git config --global user.name $username
    Write-SuccessMsg "Git username set to: $username"

    # Set Git email
    git config --global user.email $email
    Write-SuccessMsg "Git email set to: $email"
}

# Set up SSH directory if not already present
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir -PathType Container)) {
    New-Item -Path $sshDir -ItemType Directory | Out-Null
    attrib -R $sshDir
    Write-SuccessMsg "~\.ssh directory created."
}
else {
    Write-Message "Directory ~\.ssh already exists."
}

# Configure SSH config file for GitHub and GitLab
$configFile = "$sshDir\config"
Check-Path -filePath $configFile
# create empty config file if it does not exist
if (-not (Test-Path $configFile)) {
    New-Item -Path $configFile -ItemType File | Out-Null
    Write-SuccessMsg "$configFile did not exist - Empty config file created."
}
if (-not (Get-Content $configFile | Select-String "Host github.com")) {
    Add-Content -Path $configFile -Value "`nHost github.com`n    HostName github.com`n    IdentityFile ~\.ssh\id_ed25519_github"
    Write-SuccessMsg "GitHub entry added to $configFile."
}
else {
    Write-Message "GitHub entry already exists in $configFile."
}

if (-not (Get-Content $configFile | Select-String "Host gitlab.com")) {
    Add-Content -Path $configFile -Value "`nHost gitlab.com`n    HostName gitlab.com`n    IdentityFile ~\.ssh\id_ed25519_gitlab"
    Write-SuccessMsg "GitLab entry added to $configFile."
}
else {
    Write-Message "GitLab entry already exists in $configFile."
}

if (-not (Get-Content $configFile | Select-String "Host ssh.dev.azure.com")) {
    Add-Content -Path $configFile -Value "`nHost ssh.dev.azure.com`n    HostName ssh.dev.azure.com`n    IdentityFile ~\.ssh\id_rsa_azuredevops"
    Write-SuccessMsg "Azure DevOps entry added to $configFile."
}
else {
    Write-Message "Azure DevOps entry already exists in $configFile."
}

# Copy and set permissions for GitHub SSH key
Check-Path -filePath "$sshDir\id_ed25519_github"
Check-Path -filePath "$sshDir\id_ed25519_github.pub"

# Copy and set permissions for GitLab SSH key
Check-Path -filePath "$sshDir\id_ed25519_gitlab"
Check-Path -filePath "$sshDir\id_ed25519_gitlab.pub"

# Copy and set permissions for Azure DevOps SSH key
Check-Path -filePath "$sshDir\id_rsa_azuredevops"
Check-Path -filePath "$sshDir\id_rsa_azuredevops.pub"

# install scoop
Write-Message "Installing Scoop..."
if (-not (Test-Path $env:USERPROFILE\scoop)) {
    # Install Scoop
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    Write-SuccessMsg "Scoop installed successfully."
}
else {
    Write-Message "Scoop is already installed."
}

# install packages
Write-Message "Installing packages..."
scoop install git
scoop install 1password-cli
scoop install starship
# install jetbrains nerd font
scoop bucket add nerd-fonts
scoop install FiraCode-NF
scoop install JetBrainsMono-NF

# copy starship config
Write-Message "Copying Starship config..."
$webClient = New-Object System.Net.WebClient
$webClient.Encoding = [System.Text.Encoding]::UTF8
$webClient.DownloadFile("https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/starship.toml", "$env:USERPROFILE\.config\starship.toml")
Clear-Variable -Name webClient

# configure scoop
Write-Message "Configuring Scoop..."
# add Invoke-Expression (&starship init powershell) to $PROFILE if the line does not exist
if (-not (Get-Content $PROFILE | Select-String "Invoke-Expression (&starship init powershell)")) {
    Write-Host "Invoke-Expression (&starship init powershell)" >> $PROFILE
    Write-SuccessMsg "Added scoop config info to $PROFILE."
}

# check with user if they want to set git username and email
$setGitUser = Read-Host "Do you want to set your Git username? (y/n)"
if ($setGitUser -eq "y") {
    # get user name and email from user
    Read-Host "Enter your Git username: " | Set-GitConfig -username $username
    Read-Host "Enter your Git email (e.g: username@users.noreply.github.com): " | Set-GitConfig -email $email
}

Write-SuccessMsg "All done!"
