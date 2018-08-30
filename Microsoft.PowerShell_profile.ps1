Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox

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
    apend-path "C:\Program Files\Git\bin"
}