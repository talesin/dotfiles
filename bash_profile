# echo bash_profile

if [[ ! -z "$BASH_PROFILE_LOADED" ]]; then
    return
fi

export BASH_SILENCE_DEPRECATION_WARNING=1

# Load shared environment variables
source $HOME/.dotfiles/profile.d/env



if is-installed launchctl; then
  launchctl setenv PATH "$PATH"
fi

source $HOME/.dotfiles/profile.d/paths

export BASH_PROFILE_LOADED=1
if [[ -z $FROM_BASHRC ]] && [[ -f $HOME/.bashrc ]]; then
    source $HOME/.bashrc
fi