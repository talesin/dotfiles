# echo zprofile start

typeset -U fpath
fdir=$HOME/.functions
fpath=($fdir $fpath)
autoload -Uz ${fdir}/*(:t)

if is-installed launchctl; then
  launchctl setenv PATH $PATH
fi

source $HOME/.profile.d/paths

export ZPROFILE_LOADED=1

# echo zprofile end
# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
