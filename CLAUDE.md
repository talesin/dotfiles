# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository managing shell configuration, development tools, and environment setup for macOS and Linux systems.

## Common Commands

### Setup and Installation
- `./setup.sh` - Main entry point; detects OS and runs platform-specific setup
- `./setup-macos.sh` - macOS setup (Homebrew, apps, symlinks)
- `./setup-linux.sh` - Linux setup (apt/dnf/yum packages, symlinks)

### Package Management
- `brew bundle --file=Brewfile.macos` - Install macOS packages

## Architecture

### Setup Scripts
- `setup.sh` - OS detection, delegates to platform scripts
- `setup-macos.sh` - Homebrew, Coursier, iTerm2, VS Code extensions, fonts
- `setup-linux.sh` - System packages (apt/dnf/yum), zellij, shells
- `setup-common.sh` - Shared functions: `install-node`, `install-zsh`, `install-bash`, `apply-dotfiles`

### Shell Configuration
- `zshrc` / `bashrc` - Shell-specific config with Oh My Zsh/Bash
- `shell-common.sh` - Shared config loaded by both shells (aliases, functions, integrations)
- `profile` / `zprofile` / `bash_profile` - Login shell setup
- `zshenv` - Zsh environment (NVM, Rust, SSH key detection)
- `aliases` - Shared aliases (`cls`, `zka`)

### Profile Configuration (`profile.d/`)
- `env` - Environment variables, loads `~/.config/env.local` for local overrides
- `paths` - PATH management via `add-path` function

### Shell Functions (`functions/`)
- `add-path` - Add directory to PATH if exists and not already present
- `is-installed` - Check if command exists
- `is-mac` / `is-linux` - OS detection
- `refresh-sshkey` - SSH agent startup and key management
- `is-expired-sshkey` - Check SSH certificate expiration
- `update-tools` - Interactive daily Homebrew update prompt

### Development Tool Configs
- `Brewfile.macos` - macOS Homebrew packages (casks, mas apps, dev tools)
- `vscode.extensions.lst` - VS Code extensions (Scala, Java, .NET, Copilot)
- `vscode.user.settings.json` - VS Code settings

### Application Configs
- `gitconfig` - Git config with `lg` alias, includes `~/.config/gitconfig.local`
- `vimrc` - Vim config with syntax highlighting, 2-space tabs
- `zellij.kdl` - Zellij terminal multiplexer keybindings

### Symlinks (`apply-dotfiles` in setup-common.sh)
Creates symlinks from repo to home directory:
- Shell configs → `~/.zshrc`, `~/.bashrc`, etc.
- Functions → `~/.functions/`
- Profile.d → `~/.profile.d/`
- Zellij → `~/.config/zellij/config.kdl`

## Key Features

- **Cross-platform**: macOS (Homebrew) and Linux (apt/dnf/yum)
- **Dual shell support**: Zsh (primary) and Bash with Oh My Zsh/Bash
- **Local overrides**: `~/.config/env.local`, `~/.config/gitconfig.local`
- **SSH key management**: Auto-start ssh-agent, certificate expiration checks
- **Zellij integration**: Auto-attach, custom keybindings, `cls` alias
- **Development**: Node.js (NVM), Rust, Scala/Java (Coursier), .NET