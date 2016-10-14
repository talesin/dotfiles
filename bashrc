if [ -d "/usr/local/bin" ] ; then
  export PATH="/usr/local/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
  export PATH="$HOME/bin:$PATH"
fi

 if [ -z "$SCALA_HOME" ] && [ -e /usr/local/share/scala ]; then
  export SCALA_HOME="/usr/local/share/scala"
  export PATH="$PATH:$SCALA_HOME/bin"
 fi

 which -s stack >/dev/null
 if [ $? -eq 0 ]; then
  export PATH=`stack path --bin-path 2>/dev/null`
 fi

 if [ -d "/usr/local/share/dotnet" ]; then
   export PATH="${PATH}:/usr/local/share/dotnet"
 fi
