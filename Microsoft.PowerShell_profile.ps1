Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox


function add-path($dir,[switch] $prepend) {
    $paths = $env:PATH -split ':'
    if ($paths -contains $dir) { return }
    if ($prepend) {
        $env:PATH = (@($dir) + $paths) -join ':'
    }
    else {
        $env:PATH = ($paths + $dir) -join ':'
    }
}

function append-path($dir) {
    add-path $dir
}

function prepend-path($dir) {
    add-path $dir -prepend
}

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