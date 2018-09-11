
# install chocolately - https://chocolatey.org/docs/installation
Set-ExecutionPolicy Bypass -Scope Process -Force
powershell -c { Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) }

choco install -y conemu
choco install -y git.install
choco install -y powershell-core --pre

$git = dir 'C:\Program Files\Git\bin\git.exe'
$pwsh = dir 'C:\Program Files\PowerShell\*\pwsh.exe' | sort -Property LastWriteTime -Descending | %{ $_.FullName } | select -First 1

# install powerline fonts
pushd $env:TEMP
& $git clone https://github.com/powerline/fonts.git
cd fonts
.\install.ps1
cd ..
del -recurse -force fonts
popd

& $pwsh -c { Install-Module posh-git -Scope AllUsers }
& $pwsh -c { Install-Module oh-my-posh -Scope AllUSers }
& $pwsh -c { Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force }