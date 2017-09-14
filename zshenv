
function append-path() {
  dir=$1
  if ! [[ "$PATH" =~ "(^|:)${dir}(/?)(:|$)" ]] && [ -d "$dir" ]; then
    # echo "Appending $dir to path"
    export PATH="${PATH}:${dir}"
  else
    # echo "$dir already in path"
  fi

  # echo $PATH
}

function prepend-path() {
  dir=$1
  if ! [[ "$PATH" =~ "(^|:)${dir}(/?)(:|$)" ]] && [ -d "$dir" ]; then
    # echo "Prepending $dir to path"
    export PATH="${dir}:${PATH}"
  else
    # echo "$dir already in path"
  fi

  # echo $PATH
}

function sublime() {
  /Applications/Sublime\ Text.app/Contents/MacOS/Sublime\ Text $@ 2>/dev/null &
}

function vscode() {
  /Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron $@ 2>/dev/null &
}

function vscode_() {
  /Applications/Visual\ Studio\ Code\ -\ Insiders.app/Contents/MacOS/Electron $@ 2>/dev/null &
}


if [ -z $ZSHENV ]; then


  # echo "Running zshenv"

  # Ensure that a non-login, non-interactive shell has a defined environment.
  if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile"
  fi

  #echo "PATH: $PATH"

  #zmodload zsh/regex

  export PATH=

  prepend-path "/usr/local/sbin"
  prepend-path "/usr/local/bin"
  prepend-path "${HOME}/.local/bin"

  append-path "/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core"
  append-path "/Applications/Xcode.app//Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
  append-path "/usr/local/share/dotnet"
  append-path "/Library/Frameworks/Mono.framework/Versions/Current/bin"

  append-path "/bin"
  append-path "/usr/bin"
  append-path "/usr/sbin"
  append-path "/sbin"
  append-path "/opt/X11/bin"

  which -s brew >/dev/null
  if [ $? -eq 0 ]; then
    export PYTHON_BIN=$(brew --prefix)/opt/python/libexec/bin

    prepend-path $PYTHON_BIN
  fi

  which -s stack >/dev/null
  if [ $? -eq 0 ]; then
    # echo "Adding stack path"
    export PATH=`stack path --bin-path 2>/dev/null`
  fi

  if [ -d "${HOME}/Documents/Projects/awssamlcliauth" ]; then
    # echo "Aliasing awsauth"
    alias awsauth='${HOME}/Documents/Projects/awssamlcliauth/auth.sh; [[ -r "$HOME/.aws/sessiontoken" ]] && . "$HOME/.aws/sessiontoken"'
  fi

  alias airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport


  #launchctl setenv PATH $PATH

  # export ZSHENV=1
fi

# read -sk