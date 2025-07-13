# echo zshenv start

# Load shared environment variables
source $HOME/.profile.d/env

# SSH key detection
if [ -d $HOME/.ssh ]; then
    setopt NULL_GLOB
    certs=($HOME/.ssh/*-cert.pub) 2>/dev/null
    unsetopt NULL_GLOB

    if [ ${#certs[@]} -gt 0 ]; then
        export SSH_PUB_KEY=${certs[1]}
    fi
fi

export OS=$(uname)

# echo zshenv end
