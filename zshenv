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

if [ -d "${HOME}/.local/bin" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

which -s stack >/dev/null
if [ $? -eq 0 ]; then
  export PATH=`stack path --bin-path 2>/dev/null`
fi

if [ -d "${HOME}/Documents/Projects/awssamlcliauth" ]; then
  alias awsauth='${HOME}/Documents/Projects/awssamlcliauth/auth.sh; [[ -r "$HOME/.aws/sessiontoken" ]] && . "$HOME/.aws/sessiontoken"'
fi

if [ -d "/usr/local/share/dotnet" ]; then
  export PATH="${PATH}:/usr/local/share/dotnet"
fi
