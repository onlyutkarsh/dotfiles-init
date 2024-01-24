# info

initial script to run to setup zsh and brew on a new WSL

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/setup.sh)"
```

```ps1
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/onlyutkarsh/dotfiles-init/main/setup.ps1').Content
```
