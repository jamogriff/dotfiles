# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started

These dotfiles provide setup for desktop and TTY computers.

### Desktop Computer

Running the `init/desktop/install-config` script will install fonts, config files and will switch the Escape and Caps Lock keys.
(If you you want to keep your Caps Lock key then run `gsettings reset org.gnome.desktop.input-sources xkb-options`).
Running the `init/desktop/install-terminal` script will install the Kitty terminal emulator.
Running `install-nvim` will install Neovim and all of its plugins and tailored configurations.
*Note that I would probably run those scripts in that order, but it may not matter*

### TTY Computer

Run `init/tty/install-config` to install TMUX, scripts and nvim config. Run `install-nvim` to install Neovim.

**Notes:**
- You'll likely need to set `export TERM=xterm-256color` in you `~/.zshrc`file.
- You should run `revert-tty-nvim-config` immediately afterward to prevent possibility of committing the file moves done in service of setting up NVim on TTY




## System Prereq's
For proper setup of everything you must have the following installed on a Linux computer:
- xclip
- tmux
- curl
- unzip
- fzf
- ripgrep

## PHP Stuff

If you're intending on using PHP then install `intelephense` via node and place your key in `~/.secrets/`.

## TODO
- Setup other useful LSP's (HTML, Css, Sass, JS, TS, Ruby, SQL...?)
- Symlink `default-packages` to $NVM_DIR in install script so global packages (mostly language servers) can be used on different versions of Node.
- Script for installing python and zuban LSP via pip

