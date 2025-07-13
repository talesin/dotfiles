# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that manages shell configuration files, development tools, and environment setup for macOS and Linux systems.

## Common Commands

### Setup and Installation
- `./setup.sh` - Main setup script that detects OS and runs appropriate platform-specific setup
- `./setup-macos.sh` - macOS-specific setup (installs Homebrew, apps, dotbot configuration)
- `./setup-linux.sh` - Linux-specific setup (installs packages, dotbot configuration)

### Dotbot Configuration
- `dotbot -c install.conf.yaml` - Apply dotfile symlinks and configurations
- The dotbot configuration links files from the repo to home directory locations

### Package Management
- `brew bundle` - Install applications and tools from Brewfile (macOS)
- `brew update && brew bundle` - Update Homebrew and install/update packages

## Architecture

### Core Components

1. **Shell Configuration**
   - `zshrc` - Zsh shell configuration with Oh My Zsh integration
   - `bashrc` - Bash shell configuration with Oh My Bash integration
   - `aliases` - Shell aliases shared across shells
   - `profile`, `zprofile`, `bash_profile` - Shell profile configurations

2. **Development Tools Setup**
   - `Brewfile` - Homebrew package definitions for macOS
   - `vscode.extensions.lst` - VS Code extensions to install
   - `packages.linux.lst` - Linux package list

3. **Configuration Files**
   - `gitconfig` - Git configuration
   - `vimrc` - Vim editor configuration
   - `zellij.kdl` - Zellij terminal multiplexer configuration

4. **Setup Scripts**
   - Modular functions for installing different components (brew, node, zsh, etc.)
   - OS detection and platform-specific execution
   - Dotbot integration for file linking

### Key Features

- **Cross-platform support**: Separate setup scripts for macOS and Linux
- **Modular installation**: Individual functions for different tools (brew, node, zsh, etc.)
- **Shell integration**: Supports both Zsh (Oh My Zsh) and Bash (Oh My Bash)
- **Development environment**: Includes VS Code, Git, Node.js, and various CLI tools
- **Terminal multiplexer**: Zellij configuration for terminal management

## File Structure

- Configuration files are stored in the repository root
- `install.conf.yaml` defines the symlink mappings via dotbot
- Setup scripts handle tool installation and environment configuration
- Platform-specific package lists maintain consistency across environments