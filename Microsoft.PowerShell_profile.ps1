if ($PSVersionTable.PSVersion.Major -lt 5.0) {
    exit
}

function Has-Module($module) {
    (Get-InstalledModule $module -ErrorAction SilentlyContinue).Count -eq 0 
}

if (Has-Module PackageManagement) {
    Install-Module -Name PackageManagement -SkipPublisherCheck -Force -AllowClobber
}

if (Has-Module posh-git) {
    if ($PSVersionTable.PSVersion.Major -ge 6.0) {
        Install-Module -Name posh-git -AllowPrerelease -Scope AllUsers -Force
    }
    else {
        Install-Module -Name posh-git -Scope AllUsers -Force
    }
}

if (Has-Module oh-my-posh) {
    if ($PSVersionTable.PSVersion.Major -ge 6.0) {
        Install-Module -Name oh-my-posh -AllowPrerelease -Scope AllUsers -Force
    }
    else {
        Install-Module -Name oh-my-posh -Scope AllUsers -Force 
    }
}

if (Has-Module PSReadLine) {
    if ($PSVersionTable.PSVersion.Major -ge 6.0) {
        Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force -SkipPublisherCheck
    }
    else {
        Install-Module -Name PSReadLine -Scope AllUsers -Force -SkipPublisherCheck
    }
}

Import-Module posh-git
Import-Module oh-my-posh
Import-Module PSReadLine

$isWin = $IsWindows -or ($env:OS -ieq "Windows_NT")
$isNix = $IsLinux -or $IsMacOS

if ($isWin) {
    # Chocolatey profile
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}

function add-path($dir,[switch] $prepend) {
    $sep = if ($IsWindows) { ";" } else { ":" }
    $paths = $env:PATH -split ':'
    if (($paths -contains $dir) -or -not (Test-Path $dir)) { return }
    if ($prepend) {
        $env:PATH = (@($dir) + $paths) -join $sep
    }
    else {
        $env:PATH = ($paths + $dir) -join $sep
    }
}

function append-path($dir) {
    add-path $dir
}

function prepend-path($dir) {
    add-path $dir -prepend
}

if ($isNix) {
    prepend-path "/usr/local/sbin"
    prepend-path "/usr/local/bin"
    prepend-path "$HOME/.local/bin"

    append-path "/Applications/Xcode.app/Contents/Developer/usr/libexec/git-core"
    append-path "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
    append-path "/usr/local/share/dotnet"
    append-path "/Library/Frameworks/Mono.framework/Versions/Current/bin"

    append-path "/bin"
    append-path "/usr/bin"
    append-path "/usr/sbin"
    append-path "/sbin"
    append-path "/opt/X11/bin"
}

elseif ($isWin) {
    append-path "C:\Program Files\Git\bin"
    append-path (dir 'C:\Program Files\PowerShell\*\pwsh.exe' | sort -Property LastWriteTime -Descending | %{ $_.DirectoryName } | select -First 1)
}

Set-Theme Agnoster