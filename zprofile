# echo zprofile

if [[ ! -z "$ZPROFILE_LOADED" ]]; then
    exit
fi

typeset -U fpath
fdir=$HOME/.functions
if [[ -z ${fpath[(r)$fdir]} ]] ; then
    export fpath=($fdir $fpath)
    autoload -Uz ${fdir}/*(:t)
fi

if is-installed launchctl; then
  launchctl setenv PATH $PATH
fi

add-path /opt/homebrew/bin
add-path $HOME/Library/Application Support/Coursier/bin
add-path $HOME/.local/bin

export ZPROFILE_LOADED=1