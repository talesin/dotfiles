# echo bashrc

if [[ -z $BASH_PROFILE_LOADED ]] && [[ -f $HOME/.bash_profile ]]; then
    FROM_BASHRC=1 source $HOME/.bash_profile
fi

# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# Path to your oh-my-bash installation.
export OSH=$HOME/.oh-my-bash
OSH_THEME="font"
OMB_USE_SUDO=true
completions=(
  git
  composer
  ssh
)
aliases=(
  general
)

plugins=(
  git
  bashmarks
)
source "$OSH"/oh-my-bash.sh

# brazil
if [ -f $HOME/.brazil_completion/bash_completion ]; then
    source $HOME/.brazil_completion/bash_completion
fi

# mise
if is-installed mise; then
    eval "$(mise activate bash)"
fi

# iterm & brew
if is-mac; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  is-installed brew && eval "$(brew shellenv)"
fi

if is-installed direnv; then
  eval "$(direnv hook bash)"
fi

function _dotnet_bash_complete()
{
  local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n' # On Windows you may need to use use IFS=$'\r\n'
  local candidates

  read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)

  read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
}

complete -f -F _dotnet_bash_complete dotnet
