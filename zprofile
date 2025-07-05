# echo zprofile start

typeset -U fpath
fdir=$HOME/.functions
if [[ -z ${fpath[(r)$fdir]} ]] ; then
    export fpath=($fdir $fpath)
    autoload -Uz ${fdir}/*(:t)
fi

if is-installed launchctl; then
  launchctl setenv PATH $PATH
fi

source $HOME/.dotfiles/profile.d/paths

export ZPROFILE_LOADED=1

# echo zprofile end