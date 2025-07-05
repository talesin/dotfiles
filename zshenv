# echo zshenv start

if [ -f $HOME/.config/env.local ]; then
    source $HOME/.config/env.local
fi

# ssh key
if [ -d $HOME/.ssh ]; then

    setopt NULL_GLOB
    certs=($HOME/.ssh/*-cert.pub) 2> /dev/null
    unsetopt NULL_GLOB

    if [ ${#certs[@]} -gt 0 ]; then
        export SSH_PUB_KEY=${certs[1]}
    fi
fi

export OS=`uname`

# node
export NODE_ENV=local
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

. "$HOME/.cargo/env"

# echo zshenv end