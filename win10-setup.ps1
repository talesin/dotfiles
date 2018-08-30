
# install chocolately - https://chocolatey.org/docs/installation
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install conemu
choco install git.install

# install powerline fonts
pushd $env:TEMP
git clone https://github.com/powerline/fonts.git
cd fonts
.\install.ps1
cd ..
del -recurse -force fonts
popd

