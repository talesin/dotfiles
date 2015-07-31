export PATH=$HOME/.cabal/bin:$PATH

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

case "$(uname -s)" in
        Darwin)
                export NVM_DIR=~/.nvm
                source $(brew --prefix nvm)/nvm.sh
                nvm use stable
        ;;

        Linux)
                echo "Linux"
        ;;
esac
