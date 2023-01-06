# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started
Running the `install-config` script will install fonts, config files and will switch the Escape and Caps Lock keys.
(If you you want to keep your Caps Lock key then run `gsettings reset org.gnome.desktop.input-sources xkb-options`).
Running the `install-terminal` script will install the Kitty terminal emulator.

## System Prereq's
To run the install script you must have the following installed on a Linux computer:
- curl
- unzip
- fzf
- ripgrep

## TODO
Symlink `default-packages` to $NVM_DIR in install script so global packages (mostly language servers) can be used on different versions of Node.

