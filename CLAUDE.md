# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository managing shell configuration, development tools, and environment setup for macOS and Linux systems.

## Common Commands

### Setup and Installation
- `./setup.sh` - Main entry point; detects OS and runs platform-specific setup. No arguments shows a checklist of steps (done steps start unticked); `--yes` runs all, `--skip a,b` excludes, `--list` shows done/pending, `--dry-run` prints what would run, `<name> [args]` runs one step or function. Without a terminal and without `--yes` it exits 2
- `./setup-macos.sh` - macOS setup (Homebrew, apps, symlinks); same options as `setup.sh`
- `./setup-linux.sh` - Linux setup (apt/dnf/yum packages, symlinks); same options as `setup.sh`
- `zellij-plugins/tab-title/build.sh` - Rebuilds the plugin and refreshes the committed `.wasm`

### Package Management
- `brew bundle --file=Brewfile.macos` - Install macOS packages

### Diagnostics
- `./check-claude-desktop-terminal.sh` - Confirms Claude Desktop's integrated terminal would not auto-attach to zellij; prints the app version and the spawn env it uses, so a marker change after an app update is visible

## Architecture

### Setup Scripts
- `setup.sh` - OS detection, delegates to platform scripts
- `setup-macos.sh` - Homebrew, Coursier, iTerm2, fonts, the `Zellij 💻.app` launcher (`install-zellij-launcher`). Steps, in order: `install-brew`, `install-brew-packages`, `register-brew-shells`, `install-iterm-integration`, `install-coursier`, `apply-dotfiles`, `seed-gitconfig`, `install-zellij-launcher`, `install-xcode`, `install-node`, `install-node-extras`, `install-powerline`, `use-brew-zsh` (the `chsh`), `install-zsh`, `install-bash`. `DIR` is resolved from the script path. Every step runs through `run-step`, so a failure is recorded and the rest still run; the script ends with one summary of what needs attention, each item with a retry command, and exits 1 if there was any. `install-brew-packages` verifies the Brewfile with `brew bundle check` afterwards, because `brew bundle` reports a failed download mid-output and can skip an entry silently; once `Xcode.app` exists it first runs `install-xcode`, since brew refuses to run until Xcode is selected and its license accepted. `install-xcode` works on `/Applications/Xcode.app` (installed by the Brewfile's `mas` entry), not the command line tools, which satisfy `xcode-select -p` on their own: it selects the app as the developer directory and runs the interactive `sudo xcodebuild -license`, so it needs a terminal. `install-coursier` runs `coursier setup` with a JVM trust store built by `build-jvm-truststore` (the JVM's own roots plus the System and login keychain certificates: Java's default store rejects the certificate of a TLS-inspecting proxy, which curl accepts, while the `KeychainStore` type alone lacks the public CAs and fails github.com), the Coursier bin directory on `PATH` (otherwise coursier offers to edit the profile files, which are symlinks into this repo), and Java stack frames kept off the screen; the full output is kept in a log when it fails
- `setup-linux.sh` - System packages (apt/dnf/yum), zellij, shells. Steps: `install-packages`, `install-fonts`, `install-zellij`, `install-powershell`, `install-dotnet`, `install-wsl-tools` (WSL only), `apply-dotfiles`, `seed-gitconfig`, `install-node`, `install-zsh`, `install-bash`; helpers such as `pwsh-arch` and `download-pwsh-asset` are not steps but run by name. Steps go through the same `run-step`/`report-problems` failure tracking as macOS, so a failed step is summarised and the script exits 1
- `setup-common.sh` - Shared functions: `install-node`, `install-zsh`, `install-bash`, `apply-dotfiles` (defaults to `$DOTFILES_DIR`, set by each platform script), `link-gitconfig`, `seed-gitconfig`, `zellij-plugin-dir`, `seed-zellij-plugin-permissions`, and the failure tracking `run-step`, `note-problem`, `report-problems`. `seed-gitconfig` gates on `user.name`/`user.email` being unset in `~/.gitconfig` (the file itself always exists after `link-gitconfig`), and records a problem instead of prompting when there is no terminal or `--yes` is set. The step registry: `add-step <function> <description> [<done-check>]` (parallel arrays `STEP_FUNCS`/`STEP_DESCS`/`STEP_CHECKS`; the done-check is a cheap, side-effect-free function returning 0 when nothing is left to do), `parse-setup-args`, `select-steps`, `step-menu` (dispatcher: `step-menu-tui`, a full-screen checklist on the alternate screen with arrows/`j`/`k`/space/SGR mouse, raw ANSI plus `stty`, with INT/TERM/HUP/EXIT traps restoring the terminal, when `TERM` is not dumb and the window fits the rows and widest line; else `step-menu-lines`, print/read/reprint; `SETUP_MENU=lines` forces the latter; bash 3.2, no UI tools), and `run-setup <platform>` which each platform script calls after registering its steps. A step whose prerequisite was unticked fails normally and appears in the summary with its retry command; there is no dependency graph

### Shell Configuration
- `zshrc` / `bashrc` - Shell-specific config with Oh My Zsh/Bash. `zshrc` takes its Oh My Zsh plugin list from the `ZSH_PLUGINS` array (default `(git vi-mode)`; set it in `~/.config/env.local` to change it) and also holds the zellij resurrect hook for shell functions (see Zellij integration)
- `shell-common.sh` - Shared config loaded by both shells (aliases, functions, integrations)
- `profile` / `zprofile` / `bash_profile` - Login shell setup
- `zshenv` - Zsh environment (NVM, Rust, SSH key detection)
- `aliases` - Shared aliases (`cls`, `zka`)

### Profile Configuration (`profile.d/`)
- `env` - Environment variables, loads `~/.config/env.local` for local overrides. Runs first in `zshenv`/`bash_profile`, so it starts by restoring the system PATH directories (`path_helper` on macOS, the conventional set elsewhere) when the inherited PATH lacks them; `nvm.sh` and everything after it need `tr` and friends. A non-interactive shell (sshd running a remote command such as `docker system dial-stdio`) never sources `paths`, so `env` also prepends `/usr/local/bin` there when it is missing
- `paths` - PATH management via `add-path` function. Sourced by the login profiles and re-sourced by `shell-common.sh`, so an interactive non-login shell (zellij pane, editor terminal) rebuilds the user-level entries; `add-path` skips entries already present

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
- `vscode.user.settings.json` - VS Code settings
- `.vscode/settings.json` - Workspace VS Code settings; points rust-analyzer at the nested `zellij-plugins/tab-title` crate via `linkedProjects`, since the repo root is not a Cargo workspace

### Application Configs
- `gitconfig` - Shared git config with the `lg` alias and per-host credential helpers (`gh` for GitHub, Git Credential Manager for Azure DevOps). Linked to `~/.config/git/config`; `~/.gitconfig` is an untracked per-machine file holding the user identity and local overrides. Git reads `~/.gitconfig` second, so it wins, and `git config --global` writes land there - Git Credential Manager records per-organisation settings that way. `link-gitconfig` in `setup-common.sh` sets this up and moves a `~/.config/gitconfig.local` from the earlier layout into `~/.gitconfig`
- `vimrc` - Vim config with syntax highlighting, 2-space tabs
- `zellij.kdl` - Zellij terminal multiplexer keybindings, plus the `terminal` block (font) for the Zellij terminal window
- `zellij-launcher/` - Sources of `~/Applications/Zellij 💻.app` (macOS): an `Info.plist` and a `launcher` script that runs `open -n -a ~/Applications/Zellij.app --args terminal --create 💻`. Zellij.app takes no session name and ignores `session_name` in the config, so launching it directly always starts a session with a generated name; the launcher opens the Zellij terminal on the same `💻` session the shell auto-attach uses. `install-zellij-launcher` in `setup-macos.sh` copies the bundle into place (a symlinked bundle is not treated as an app by Spotlight or the Dock), borrows Zellij.app's icon, and first runs `zellij setup --install-desktop-entry` when Zellij.app is missing. Re-run `./setup-macos.sh install-zellij-launcher` after editing the sources
- `zellij-layouts/` - Named zellij layouts (`default.kdl`), resolved by bare name via `zellij --layout <name>`; holds the swap layouts cycled by `next-swap-layout`
- `zellij-plugins/` - `tab-title/` is a Rust crate compiled to `wasm32-wasip1`; the committed `zellij-tab-title.wasm` renames each tab to its focused pane's title; loaded by the `load_plugins` block in `zellij.kdl`; committed so machines without Rust need no build step. Its permissions are seeded into zellij's permission cache by `apply-dotfiles` (`seed-zellij-plugin-permissions`), because zellij's grant prompt cannot surface for a pane-less background plugin - see `zellij-plugins/README.md`
- `claude-statusline.sh` - Claude Code status line, shared by the primary and secondary profiles (see `functions/claude`). Takes the profile name (`primary`/`secondary`) as `$1`; renders a colored badge plus cwd, git branch, and model. Wired in via each profile's `~/.claude*/settings.json` `statusLine` key (not managed by `apply-dotfiles` - set up manually per machine).

### Symlinks (`apply-dotfiles` in setup-common.sh)
Creates symlinks from repo to home directory:
- Shell configs → `~/.zshrc`, `~/.bashrc`, etc.
- Git → `~/.config/git/config`
- Functions → `~/.functions/`
- Profile.d → `~/.profile.d/`
- Zellij → `~/.config/zellij/config.kdl`, `~/.config/zellij/layouts`
- Zellij tab-title plugin → the OS-specific zellij plugin dir

## Key Features

- **Cross-platform**: macOS (Homebrew) and Linux (apt/dnf/yum)
- **Dual shell support**: Zsh (primary) and Bash with Oh My Zsh/Bash
- **Local overrides**: `~/.config/env.local`, `~/.gitconfig`
- **SSH key management**: Auto-start ssh-agent, certificate expiration checks
- **Zellij integration**: Auto-attach (interactive human terminals only - see `zellij-autostart-wanted`; agent runners like Claude Desktop get a plain shell, since `attach --create` would join the human's live session rather than make a new one), custom keybindings, `cls` alias, automatic tab names from pane titles, resurrection of panes running shell functions. Zellij saves a pane by the argv of its foreground process, so a pane running the `claude` function would be saved as bare `claude`, without `--secondary` and outside the shell that defines the function. In zsh inside zellij, a `preexec` hook in `zshrc` registers `$SHELL -ic '<typed line>'` through `zellij action set-resurrect-command` when the first word of the line is a function listed in `ZELLIJ_RESURRECT_FUNCTIONS` (default `(claude)`; set the array in `~/.config/env.local` to extend it), and a `precmd` hook clears it once the pane is back at its prompt. Lines where the function is not the first word (`FOO=1 claude`, `cd x && claude`) keep zellij's default discovery, and bash has no hook. `shell-common.sh` skips `update-tools` for a shell started with a command string, so the resurrected `zsh -ic` pane does not stop at the update prompt. Panes are non-login shells (no `zprofile`), so their PATH comes from `profile.d/env` restoring the system directories and `shell-common.sh` re-sourcing `profile.d/paths`
- **Development**: Node.js (NVM), Rust, Scala/Java (Coursier), .NET