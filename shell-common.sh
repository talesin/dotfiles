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
  export ZELLIJ_AUTO_ATTACH=true
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(zellij setup --generate-auto-start zsh)"
  # TODO: Uncomment these lines if you want to enable Zellij auto-start for Bash
  # elif [ -n "$BASH_VERSION" ]; then
    # eval "$(zellij setup --generate-auto-start bash)"
  fi
fi

# Update tools
update-tools