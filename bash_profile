# echo bash_profile

if [[ ! -z "$BASH_PROFILE_LOADED" ]]; then
    exit
fi

export BASH_SILENCE_DEPRECATION_WARNING=1

if [ -f $HOME/.config/env.local ]; then
    source $HOME/.config/env.local
fi

export NODE_ENV=local
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

. "$HOME/.cargo/env"

if [ -f $HOME/.aliases ]; then
    source $HOME/.aliases
fi

if [ -d $HOME/.functions ]; then
    pushd $HOME/.functions >/dev/null

    for fn in *; do
        eval "function $fn { source $HOME/.functions/$fn; }"
    done

    popd >/dev/null
fi

if is-installed launchctl; then
  launchctl setenv PATH "$PATH"
fi

add-path /opt/homebrew/bin
add-path "$HOME/Library/Application Support/Coursier/bin"
add-path $HOME/.local/bin
add-path $HOME/.cargo/bin
add-path $HOME/.lmstudio/bin
add-path $HOME/.codeium/windsurf/bin

export BASH_PROFILE_LOADED=1
if [[ -z $FROM_BASHRC ]] && [[ -f $HOME/.bashrc ]]; then
    source $HOME/.bashrc
fi