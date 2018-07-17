# MacOS

- `curl -s https://raw.githubusercontent.com/talesin/dotfiles/master/macos-setup.sh | bash`
- Open iTerm and set a powerline font for your profile

# Windows

## Cygwin

- Ensure you can run PowerShell scripts
    - Run the following as administrator if you can't: `set-executionpolicy unrestricted`
    - And check that you have the latest version by running `host` at the prompt checking if you need to [upgrade](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell)
- Install [Cygwin](https://www.cygwin.com/setup-x86_64.exe)
- Install [ConEmu](https://www.fosshub.com/ConEmu.html)
    - Choose CygWin bash as your shell
- From a Cygwin shell run:
    - `curl -s https://raw.githubusercontent.com/talesin/dotfiles/cygwin-setup.sh | bash`
- Open the ConEmu settings and choose a powerline font

## Windows Subsystem for Linux

- Install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

# References

- [iTerm2](https://www.iterm2.com)
- [Homebrew](https://brew.sh)
- [Dotbot](https://git.io/dotbot)
- [direnv](https://direnv.net/)
- [Byobu](http://byobu.co/)
- [Fish](https://fishshell.com)
- [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish)
- [Powerline fonts](https://github.com/powerline/fonts)
- [Cygwin](https://www.cygwin.com)
- [ConEmu](https://conemu.github.io)
- [PowerShell](https://docs.microsoft.com/en-us/powershell)