#!/usr/bin/env bash
DIR=`cd $(dirname $0); pwd`

mkdir ~/.config/powershell/
pwsh -c { Install-Module posh-git -Scope AllUsers }
pwsh -c { Install-Module oh-my-posh -Scope AllUsers }
pwsh -c { Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force }
grep -sq pwsh /etc/shells
if [ $? -eq 1 ]; then
    sudo sh -c "echo /usr/local/bin/pwsh >> /etc/shells"
fi