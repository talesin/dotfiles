# Bash-specific configuration
# echo bashrc

if [[ -z $BASH_PROFILE_LOADED ]] && [[ -f $HOME/.bash_profile ]]; then
    FROM_BASHRC=1 source $HOME/.bash_profile
fi

# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# Oh My Bash (bash-specific)
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

# Load shared shell configuration
source ~/.shell-common.sh
