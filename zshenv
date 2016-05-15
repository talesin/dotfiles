#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

if [ -d "{HOME}/.local/bin" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if [ -d "$HOME/Library/Haskell/bin" ]; then
  export PATH="$PATH:$HOME/Library/Haskell/bin"
fi

if [ -d "${HOME}/Documents/Projects/awssamlcliauth" ]; then
  alias awsauth='${HOME}/Documents/Projects/awssamlcliauth/auth.sh; [[ -r "$HOME/.aws/sessiontoken" ]] && . "$HOME/.aws/sessiontoken"'
fi
