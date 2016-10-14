#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

if [ -z $ZSHENV ]; then

  # Ensure that a non-login, non-interactive shell has a defined environment.
  if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile"
  fi

  #echo "PATH: $PATH"

  zmodload zsh/regex

  if ! [[ "$PATH" -regex-match "(^|:)/usr/local/bin(/?)(:|$)" ]]; then
    #echo "Adding /usr/local/bin to path"
    export PATH="/usr/local/bin:${PATH}"
  fi

  if ! [[ "$PATH" -regex-match "(^|:)${HOME}/.local/bin(/?)(:|$)" ]] && [ -d "${HOME}/.local/bin" ]; then
    #echo "Adding ${HOME}/.local/bin to path"
    export PATH="${HOME}/.local/bin:${PATH}"
  fi

  which -s stack >/dev/null
  if [ $? -eq 0 ]; then
    #echo "Adding stack path"
    export PATH=`stack path --bin-path 2>/dev/null`
  fi

  if [ -d "${HOME}/Documents/Projects/awssamlcliauth" ]; then
    #echo "Aliasing awsauth"
    alias awsauth='${HOME}/Documents/Projects/awssamlcliauth/auth.sh; [[ -r "$HOME/.aws/sessiontoken" ]] && . "$HOME/.aws/sessiontoken"'
  fi

  if ! [[ "$PATH" -regex-match "(^|:)/usr/local/share/dotnet(/?)(:|$)" ]] && [ -d "/usr/local/share/dotnet" ]; then
    #echo "Ading dotnet to path"
    export PATH="${PATH}:/usr/local/share/dotnet"
  fi

  function sublime() {
    /Applications/Sublime\ Text.app/Contents/MacOS/Sublime\ Text $@ 2>/dev/null &
  }

  function vscode() {
    /Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron $@ 2>/dev/null &
  }

  function vscode_() {
  }

  #launchctl setenv PATH $PATH

  ZSHENV=1
fi
