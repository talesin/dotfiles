# MacOS

- `curl -s https://raw.githubusercontent.com/talesin/dotfiles/master/macos-setup.sh | bash`
- Open iTerm and set a powerline font for your profile

# Windows

- Ensure you can run PowerShell scripts
    - Run the following as administrator if you can't: `set-executionpolicy unrestricted`
    - And check that you have the latest version by running `host` at the prompt checking if you need to [upgrade](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell)
- Run the following (rebooting and rerunning as necessary):
    - `iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/talesin/dotfiles/master/win-setup.ps1'))`
- Open the ConEmu settings and choose a powerline font

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