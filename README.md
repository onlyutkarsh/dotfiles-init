# dotfiles-init

Bootstrap script to set up git, 1password-cli, and chezmoi on a new machine.

## Usage

### macOS / Linux / WSL

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/setup.sh)"
```

### Windows (PowerShell)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/setup.ps1').Content
```

## What it does

- Installs Homebrew (macOS/Linux) or Scoop (Windows)
- Installs git, 1password-cli, and chezmoi
- Sets up SSH config for GitHub, GitLab, and Azure DevOps
- Prompts to copy SSH public keys from 1Password

## Next steps

After setup completes, initialize chezmoi:

```bash
chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git
```
