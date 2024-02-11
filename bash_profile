# echo bash_profile

if [[ ! -z "$BASH_PROFILE_LOADED" ]]; then
    exit
fi

export BASH_SILENCE_DEPRECATION_WARNING=1

if [ -f $HOME/.zshenv ]; then
    source $HOME/.zshenv
elif [ -f $HOME/.config/env.local ]; then
    source $HOME/.config/env.local
fi

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

if [ -d $HOME/.functions ]; then
    pushd $HOME/.functions >/dev/null

    for fn in *; do
        eval "function $fn { source $HOME/.functions/$fn; }"
    done

    popd >/dev/null
fi

if is-installed launchctl; then
  launchctl setenv PATH $PATH
fi

add-path $HOME/Library/Application Support/Coursier/bin
add-path $HOME/.local/bin

if [[ -z $FROM_BASHRC ]] && [[ -f $HOME/.bashrc ]]; then
    source $HOME/.bashrc
fi

export BASH_PROFILE_LOADED=1