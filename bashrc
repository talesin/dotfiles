# echo bashrc

if [[ -f $HOME/.bashrc ]]; then
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

