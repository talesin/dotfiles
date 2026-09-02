# echo "Loading common shell configuration..."

# Common shell configuration for both zsh and bash
# This file contains shared functionality that works across all shells

# Load aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Load functions
if [ -d ~/.functions ]; then
  if [ -n "$ZSH_VERSION" ]; then
    # Zsh autoload mechanism (eval hides zsh-only glob syntax from bash's parser)
    typeset -U fpath
    fdir=$HOME/.functions
    fpath=($fdir $fpath)
    eval 'autoload -Uz ${fdir}/*(:t)'
  else
    # Bash/other shells manual sourcing
    pushd ~/.functions >/dev/null
    for fn in *; do
        eval "function $fn { source ~/.functions/$fn; }"
    done
    popd >/dev/null
  fi
fi

# Set the terminal title to the current folder name; while a command runs (zsh
# only), it shows the command name instead, reverting at the next prompt.
# Zellij exposes this as the pane title, which the zellij-tab-title plugin
# mirrors into the tab name. Overrides OMZ/OMB title since shell-common.sh
# loads after them. Zellij may prepend its session name to the terminal title,
# which is expected.
set-terminal-title() {
  printf '\e]0;%s\a' "${PWD##*/}"
}

if [ -n "$ZSH_VERSION" ]; then
  set-terminal-title-preexec() {
    printf '\e]0;%s\a' "${1%% *}"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd set-terminal-title
  add-zsh-hook preexec set-terminal-title-preexec
elif [ -n "$BASH_VERSION" ]; then
  PROMPT_COMMAND="set-terminal-title${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

# iTerm integration (works for both shells)
if is-mac; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Homebrew shellenv (works for both shells)
if is-installed brew; then
  eval "$(brew shellenv)"
fi

# Direnv integration
if is-installed direnv; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(direnv hook zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(direnv hook bash)"
  fi
fi

# Dotnet completion (shell-specific implementations)
if is-installed dotnet; then
  if [ -n "$ZSH_VERSION" ]; then
    _dotnet_zsh_complete() {
      local cmd="${(j: :)words}"  # join words array into a single command-line string
      local completions=("${(@f)$("$HOME/.dotnet/dotnet" complete --position "${#cmd}" "$cmd" 2>/dev/null)}")
      compadd -a completions
      # dotnet complete never suggests project files — add them for positional args
      [[ "${words[$CURRENT]}" != -* ]] && _files -g '*.{sln,slnx,csproj,fsproj,vbproj}'
    }
    compdef _dotnet_zsh_complete dotnet

  elif [ -n "$BASH_VERSION" ]; then
    _dotnet_bash_complete() {
      local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n'
      local candidates
      read -d '' -ra candidates < <("$HOME/.dotnet/dotnet" complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)
      read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
    }
    complete -f -F _dotnet_bash_complete dotnet
  fi
fi

# Git worktree helper (cdgit) branch completion
if [ -n "$ZSH_VERSION" ]; then
  compdef _cdgit cdgit
elif [ -n "$BASH_VERSION" ]; then
  _cdgit_bash_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local -a items
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      mapfile -t items < <(
        { git for-each-ref --format='%(refname:short)' refs/heads
          git for-each-ref --format='%(refname:lstrip=3)' refs/remotes
        } 2>/dev/null | grep -v '^HEAD$' | sort -u
      )
    else
      mapfile -t items < <(git-repos)
    fi
    COMPREPLY=($(compgen -W "${items[*]}" -- "$cur"))
  }
  complete -F _cdgit_bash_complete cdgit
fi

# PowerShell (.ps1) completion
# ${(e)...} expands shell variables the user may have typed (e.g. $PROFILE_HOME/...)
if [ -n "$ZSH_VERSION" ]; then
  _ps1_zsh_complete() {
    local script="${(e)words[1]}"
    # Bare names resolve off PATH ($commands is zsh's command hash). pwsh does
    # its own PATH lookup, so this is only here to give the python fallback
    # below something to parse.
    [[ -f "$script" ]] || script="${commands[$script]}"
    # Resolve on first use, and re-resolve if the cached path stops being
    # executable, so running install-powershell takes effect in an
    # already-running shell. native-pwsh skips the WSL scripts/pwsh shim,
    # which would otherwise spawn a Windows pwsh.exe (plus path translation)
    # on every Tab press.
    [[ -x "$_ps1_pwsh" ]] || _ps1_pwsh="$(native-pwsh)"
    if [[ -n "$_ps1_pwsh" ]]; then
      local line raw
      line="${(e)${(j: :)words[1,-1]}}"
      raw="$("$_ps1_pwsh" -NoProfile -NonInteractive \
            -File "${HOME}/.dotfiles/scripts/pwsh-complete.ps1" \
            -InputLine "$line" -CursorPos "${#line}" -WorkingDir "$PWD" 2>/dev/null)"
      [[ -n "$raw" ]] && { compadd -- "${(@f)raw}"; return; }
    fi
    [[ -f "$script" ]] || return 1
    local -a params
    params=("${(f)$(python3 "${HOME}/.dotfiles/scripts/ps1-params.py" "$script" 2>/dev/null)}")
    (( ${#params} == 0 )) && return 1
    compadd -- "${params[@]}"
  }
  compdef _ps1_zsh_complete -p '*.ps1'
elif [ -n "$BASH_VERSION" ]; then
  _ps1_bash_complete() {
    local script="${COMP_WORDS[0]}"
    [[ -f "$script" ]] || return
    local prefix="${COMP_WORDS[COMP_CWORD]}"
    local IFS=$'\n'
    COMPREPLY=($(compgen -W "$(python3 "${HOME}/.dotfiles/scripts/ps1-params.py" "$script" 2>/dev/null)" -- "$prefix"))
  }
  _ps1_bash_register() {
    local dir f
    local old_nullglob; old_nullglob="$(shopt -p nullglob)"
    shopt -s nullglob
    while IFS= read -rd: dir; do
      [[ -d "$dir" ]] || continue
      for f in "$dir"/*.ps1; do
        complete -F _ps1_bash_complete "${f##*/}"
      done
    done <<< "${PATH}:"
    eval "$old_nullglob"
  }
  _ps1_bash_register
fi

# Zellij integration (works for both shells)
if is-installed zellij && [[ -t 1 ]]; then
  if [[ -z "$ZELLIJ" && -z "$NO_ZELLIJ" ]]; then
    # Clean up exited sessions
    zellij ls 2>/dev/null | grep EXITED | awk '{print $1}' | sed -e 's/\x1B\[[0-9;]*[mG]//g' | xargs -I % zellij d % 2>/dev/null
    if [ -n "$WSL_DISTRO_NAME" ]; then
      # On a cold WSL2 start, Windows Terminal hasn't propagated the real
      # pane size to the pty by the time the shell runs. Wait (up to ~1s)
      # for the pty to report a non-default size so zellij --create lays
      # out panes at the real dimensions instead of 80x24.
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        [ "$(tput cols 2>/dev/null || echo 0)" -gt 80 ] && break
        sleep 0.1
      done
    fi
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
      exec zellij attach --create "vscode-$(basename "$PWD")"
    else
      exec zellij attach --create "💻"
    fi
  fi
fi

# Start ssh-agent and load keys
if type refresh-sshkey >/dev/null 2>&1; then
  refresh-sshkey
fi

# Update tools
update-tools
