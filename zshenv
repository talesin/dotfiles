# echo zshenv

if [ -f $HOME/.config/env.local ]; then
    source $HOME/.config/env.local
fi

# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false
export AWS_EC2_METADATA_DISABLED=true

# ssh key
certs=($HOME/.ssh/*-cert.pub)
if [ ${#certs[@]} -gt 0 ]; then
    export SSH_PUB_KEY=${certs[1]}
fi

export OS=`uname`

# node
export NODE_ENV=local
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 