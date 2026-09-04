# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository managing shell configuration, development tools, and environment setup for macOS and Linux systems.

## Common Commands

### Setup and Installation
- `./setup.sh` - Main entry point; detects OS and runs platform-specific setup
- `./setup-macos.sh` - macOS setup (Homebrew, apps, symlinks)
- `./setup-linux.sh` - Linux setup (apt/dnf/yum packages, symlinks)
- `zellij-plugins/tab-title/build.sh` - Rebuilds the plugin and refreshes the committed `.wasm`

### Package Management
- `brew bundle --file=Brewfile.macos` - Install macOS packages

### Diagnostics
- `./check-claude-desktop-terminal.sh` - Confirms Claude Desktop's integrated terminal would not auto-attach to zellij; prints the app version and the spawn env it uses, so a marker change after an app update is visible

## Architecture

### Setup Scripts
- `setup.sh` - OS detection, delegates to platform scripts
- `setup-macos.sh` - Homebrew, Coursier, iTerm2, VS Code extensions, fonts
- `setup-linux.sh` - System packages (apt/dnf/yum), zellij, shells
- `setup-common.sh` - Shared functions: `install-node`, `install-zsh`, `install-bash`, `apply-dotfiles`, `zellij-plugin-dir`, `seed-zellij-plugin-permissions`

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
- `is-agent-shell` - True when the shell was spawned by an AI agent or CI (`CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `AI_AGENT`, `CLAUDE_CODE_SESSION_ID`, `CI`, `TERM=dumb`, `TERM_PROGRAM=claude-desktop`) rather than by a human
- `zellij-autostart-wanted` - Gates the zellij auto-attach in `shell-common.sh`. Requires an interactive shell with a tty on all three descriptors, no `ZELLIJ*` vars already set, `NO_ZELLIJ` unset, `is-agent-shell` false, and a recognised terminal emulator (`TERM_PROGRAM`, `LC_TERMINAL`, `WT_SESSION`, `SSH_TTY`/`SSH_CONNECTION`, or a Linux emulator marker). Claude Desktop's integrated terminal spawns `$SHELL -l` on a real pty with the GUI env and identifies itself only through `TERM_PROGRAM=claude-desktop`, which `is-agent-shell` catches; run `./check-claude-desktop-terminal.sh` after a Desktop update to confirm the gate still holds. Set `ZELLIJ_AUTOSTART=1` in `~/.config/env.local` for a real terminal that sets no emulator marker
- `refresh-sshkey` - SSH agent startup and key management
- `is-expired-sshkey` - Check SSH certificate expiration
- `update-tools` - Interactive daily Homebrew update prompt
- `slugify` - Convert a string to a lowercase, dash-separated slug
- `claude` - Wraps the `claude` CLI to switch config profiles via `CLAUDE_CONFIG_DIR`. Default invokes it normally (`~/.claude`, primary profile). `--secondary` points at `~/.claude-secondary`, sharing `history.jsonl` and `plans/` with the primary profile via symlink but keeping settings, MCP servers, and permissions separate. First use seeds `~/.claude-secondary/settings.json` with a status line so the profile is visually distinguishable (see `claude-statusline.sh`).

### Development Tool Configs
- `Brewfile.macos` - macOS Homebrew packages (casks, mas apps, dev tools)
- `vscode.extensions.lst` - VS Code extensions (Scala, Java, .NET, Copilot)
- `vscode.user.settings.json` - VS Code settings
- `.vscode/settings.json` - Workspace VS Code settings; points rust-analyzer at the nested `zellij-plugins/tab-title` crate via `linkedProjects`, since the repo root is not a Cargo workspace

### Application Configs
- `gitconfig` - Git config with `lg` alias, includes `~/.config/gitconfig.local`
- `vimrc` - Vim config with syntax highlighting, 2-space tabs
- `zellij.kdl` - Zellij terminal multiplexer keybindings
- `zellij-layouts/` - Named zellij layouts (`default.kdl`), resolved by bare name via `zellij --layout <name>`; holds the swap layouts cycled by `next-swap-layout`
- `zellij-plugins/` - `tab-title/` is a Rust crate compiled to `wasm32-wasip1`; the committed `zellij-tab-title.wasm` renames each tab to its focused pane's title; loaded by the `load_plugins` block in `zellij.kdl`; committed so machines without Rust need no build step. Its permissions are seeded into zellij's permission cache by `apply-dotfiles` (`seed-zellij-plugin-permissions`), because zellij's grant prompt cannot surface for a pane-less background plugin - see `zellij-plugins/README.md`
- `claude-statusline.sh` - Claude Code status line, shared by the primary and secondary profiles (see `functions/claude`). Takes the profile name (`primary`/`secondary`) as `$1`; renders a colored badge plus cwd, git branch, and model. Wired in via each profile's `~/.claude*/settings.json` `statusLine` key (not managed by `apply-dotfiles` - set up manually per machine).

### Symlinks (`apply-dotfiles` in setup-common.sh)
Creates symlinks from repo to home directory:
- Shell configs → `~/.zshrc`, `~/.bashrc`, etc.
- Functions → `~/.functions/`
- Profile.d → `~/.profile.d/`
- Zellij → `~/.config/zellij/config.kdl`, `~/.config/zellij/layouts`
- Zellij tab-title plugin → the OS-specific zellij plugin dir

## Key Features

- **Cross-platform**: macOS (Homebrew) and Linux (apt/dnf/yum)
- **Dual shell support**: Zsh (primary) and Bash with Oh My Zsh/Bash
- **Local overrides**: `~/.config/env.local`, `~/.config/gitconfig.local`
- **SSH key management**: Auto-start ssh-agent, certificate expiration checks
- **Zellij integration**: Auto-attach (interactive human terminals only - see `zellij-autostart-wanted`; agent runners like Claude Desktop get a plain shell, since `attach --create` would join the human's live session rather than make a new one), custom keybindings, `cls` alias, automatic tab names from pane titles
- **Development**: Node.js (NVM), Rust, Scala/Java (Coursier), .NET