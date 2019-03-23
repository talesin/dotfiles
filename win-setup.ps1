# Set-ExecutionPolicy Bypass -Scope Process -Force

function Install-Updates {
    wuauclt.exe /updatenow
}

function Install-Chocolatey() {
    # install chocolately - https://chocolatey.org/docs/installation
    choco -? 2>&1>$null
    if (-not $?) {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

        choco -? 2>&1>$null
        if (-not $?) {
            Read-Host "Press enter to reboot your computer, then run this script again. Ctrl-C to break out"
            shutdown /r /f
            Exit-PSSession
        }
    }

    choco feature enable -name=exitOnRebootDetected
}

function Download-File($url, $path) {
    if (-not (Test-Path $path)) {
        curl -s "$url" -o "$path"
    }    
}

function Install-Prerequisites() {
    if ([System.Environment]::OSVersion.Version -eq "6.1.7600.0") {
        choco install -y KB976932 
        Read-Host "Press enter to reboot your computer, then run this script again. Ctrl-C to break out"
        shutdown /r /f
        Exit-PSSession
    }

    if ($PSVersionTable.PSVersion.Major -lt 5.0) {
        choco upgrade -y curl 7zip
        $zip = 'C:\Program Files\7-Zip\7z.exe'

        Download-File 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe' "$env:TEMP\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
        Start-Process "$env:TEMP\NDP452-KB2901907-x86-x64-AllOS-ENU.exe" -Wait -ArgumentList "/passive"

        Download-File 'http://download.microsoft.com/download/0/6/5/0658B1A7-6D2E-474F-BC2C-D69E5B9E9A68/MicrosoftEasyFix51044.msi' "$env:TEMP\MicrosoftEasyFix51044.msi"
        Start-Process "$env:TEMP\MicrosoftEasyFix51044.msi" -Wait -ArgumentList "/passive"

        Download-File 'https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip' "$env:TEMP\Win7AndW2K8R2-KB3191566-x64.zip"
        & $zip e -y "$env:TEMP\Win7AndW2K8R2-KB3191566-x64.zip"
        & "$env:TEMP\Install-WMF5.1.ps1" -Confirm -AcceptEULA -AllowRestart

        Read-Host "Press enter to reboot your computer, then run this script again. Ctrl-C to break out"
        shutdown /r /f
        Exit-PSSession
    }
}

function Install-Apps() {
    choco upgrade -y dotnetcore-runtime conemu git.install powershell powershell-core
}

function Install-Powerline() {
    # install powerline fonts
    # & $git clone https://github.com/powerline/fonts.git
    # cd fonts
    # .\install.ps1
    # cd ..
    # del -recurse -force fonts
}


function Setup-Powershell() {
    Install-Module posh-git -Scope AllUsers -Confirm
    Install-Module oh-my-posh -Scope AllUSers -Confirm
    Install-Module PSReadLine -Scope AllUsers -Confirm
}

function Setup-Bash() {
    & "C:\Program Files\Git\bin\bash" -c "curl -s 'https://raw.github.com/ohmybash/oh-my-bash/master/tools/install.sh' | bash"
}

pushd $env:TEMP

Install-Updates
Install-Chocolatey
Install-Prerequisites
Install-Apps
Install-Powerline
Setup-Powershell
Setup-Bash

popd