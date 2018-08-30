
# install chocolately - https://chocolatey.org/docs/installation
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install conemu
choco install git.install
choco install powershell-core --pre

# install powerline fonts
pushd $env:TEMP
git clone https://github.com/powerline/fonts.git
cd fonts
pswh -File .\install.ps1
cd ..
del -recurse -force fonts
popd

pwsh -c { Install-Module posh-git -Scope CurrentUser }
pwsh -c { Install-Module oh-my-posh -Scope CurrentUser }
pwsh -c { Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force }