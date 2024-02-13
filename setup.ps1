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

Check-Path -filePath $configFile

# Copy and set permissions for GitHub SSH key
Check-Path -filePath "$sshDir\id_ed25519_github"
Check-Path -filePath "$sshDir\id_ed25519_github.pub"

# Copy and set permissions for GitLab SSH key
Check-Path -filePath "$sshDir\id_ed25519_gitlab"
Check-Path -filePath "$sshDir\id_ed25519_gitlab.pub"

# Copy and set permissions for Azure DevOps SSH key
Check-Path -filePath "$sshDir\id_rsa_azuredevops"
Check-Path -filePath "$sshDir\id_rsa_azuredevops.pub"

# get user name and email from user
Read-Host "Enter your GitHub username: " | Set-GitConfig -username $username
Read-Host "Enter your GitHub email: " | Set-GitConfig -email $email
#Set-GitConfig -username "Utkarsh Shigihalli" -email "onlyutkarsh@users.noreply.github.com"

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

Write-SuccessMsg "All done!"
