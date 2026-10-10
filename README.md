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

- **Linux/WSL**: Installs required system dependencies (unzip, build-essential, curl, file, git)
- Installs Homebrew (macOS/Linux) or Scoop (Windows)
- Installs git, 1password-cli, and chezmoi
- **Windows**: Installs AutoHotkey from Scoop's extras bucket
- Sets up SSH config for GitHub, GitLab, and Azure DevOps (skipped on WSL, handled by Windows)
- **WSL**: Configures git to use Windows OpenSSH for 1Password SSH agent integration
- Configures host-specific public-key selectors matching the dotfiles SSH config
- Checks for `github.pub`, `gitlab.pub`, and `ado.pub` and validates them with `ssh-keygen` (Windows and native macOS/Linux only)

Install and unlock 1Password desktop and enable its SSH agent under Settings > Developer. The CLI alone does not provide an SSH agent. Download each matching **Public key** from 1Password into `~/.ssh/` using the filenames above, and register it with the corresponding Git host. Private keys stay in 1Password. The public files select which agent key to use for each host.

On WSL, run the Windows bootstrap first. Public-key files and the 1Password agent belong on Windows; the WSL SSH config remains empty.

## Next steps

After setup completes, initialize chezmoi:

```bash
chezmoi init --apply git@github.com:onlyutkarsh/dotfiles.git
```
