function vscode
  if which -s code-insiders
    code-insiders $argv
  else if test "/Applications/Visual Studio Code - Insiders.app/Contents/MacOS/Electron"
    "/Applications/Visual Studio Code - Insiders.app/Contents/MacOS/Electron" $argv &
  else if -s code
    code $argv
  else if test "/Applications/Visual Studio Code.app/Contents/MacOS/Electron"
    "/Applications/Visual Studio Code.app/Contents/MacOS/Electron" $argv &
  else
    echo "Cannot find vscode"
  end
end

