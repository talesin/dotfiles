# echo bash_profile

if [[ ! -z "$BASH_PROFILE_LOADED" ]]; then
    return
fi

export BASH_SILENCE_DEPRECATION_WARNING=1

# Load functions first (needed by other scripts)
if [ -d ~/.functions ]; then
    for fn in ~/.functions/*; do
        if [ -f "$fn" ]; then
            func_name=$(basename "$fn")
            eval "function $func_name() { source ~/.functions/$func_name; }"
        fi
    done
fi

# Load shared environment variables
source $HOME/.profile.d/env

if is-installed launchctl; then
    launchctl setenv PATH "$PATH"
fi

source $HOME/.profile.d/paths

export BASH_PROFILE_LOADED=1
if [[ -z $FROM_BASHRC ]] && [[ -f $HOME/.bashrc ]]; then
    source $HOME/.bashrc
fi
