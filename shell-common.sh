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
    # Zsh autoload mechanism
    typeset -U fpath
    fdir=$HOME/.functions
    if [[ -z ${fpath[(r)$fdir]} ]] ; then
        export fpath=($fdir $fpath)
        for func_file in $fdir/*; do
            if [ -f "$func_file" ]; then
                autoload -Uz $(basename "$func_file")
            fi
        done
    fi
  else
    # Bash/other shells manual sourcing
    pushd ~/.functions >/dev/null
    for fn in *; do
        eval "function $fn { source ~/.functions/$fn; }"
    done
    popd >/dev/null
  fi
fi

# Set terminal title to current folder name
# Overrides OMZ/OMB title since shell-common.sh loads after them
# Zellij may prepend its session name, which is expected
set-terminal-title() {
  printf '\e]0;%s\a' "${PWD##*/}"
}

if [ -n "$ZSH_VERSION" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd set-terminal-title
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
      local completions=("$(dotnet complete "$words")")
      if [ -z "$completions" ]; then
        _arguments '*::arguments: _normal'
        return
      fi
      _values="${(ps:\n:)completions}"
    }
    compdef _dotnet_zsh_complete dotnet
  elif [ -n "$BASH_VERSION" ]; then
    _dotnet_bash_complete() {
      local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n'
      local candidates
      read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)
      read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
    }
    complete -f -F _dotnet_bash_complete dotnet
  fi
fi
# Zellij integration (works for both shells)
if is-installed zellij; then
  if [[ -z "$ZELLIJ" ]]; then
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
    exec zellij attach --create "💻"
  fi
fi

# Start ssh-agent and load keys
if type refresh-sshkey >/dev/null 2>&1; then
  refresh-sshkey
fi

# Update tools
update-tools
