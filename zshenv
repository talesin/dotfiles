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

# Add GHC 7.10.2 to the PATH, via https://ghcformacosx.github.io/
if [ -d "/Applications/ghc-7.10.2.app" ]; then
  export GHC_DOT_APP="/Applications/ghc-7.10.2.app"
  export PATH="${HOME}/.local/bin:${HOME}/.cabal/bin:${GHC_DOT_APP}/Contents/bin:${PATH}"
fi

if [ -d "$HOME/Library/Haskell/bin" ]; then
  export PATH="$PATH:$HOME/Library/Haskell/bin"
fi
