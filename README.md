# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started
Running the `install-config` script will install fonts, config files and will switch the Escape and Caps Lock keys.
(If you you want to keep your Caps Lock key then run `gsettings reset org.gnome.desktop.input-sources xkb-options`).
Running the `install-terminal` script will install the Kitty terminal emulator.
Running `install-nvim` will install Neovim and all of its plugins and tailored configurations.
*Note that I would probably run those scripts in that order, but it may not matter*

## System Prereq's
For proper setup of everything you must have the following installed on a Linux computer:
- tmux
- curl
- unzip
- fzf
- ripgrep

## TODO
- Install LSP's (and configure in Nvim) for HTML, Css, Sass, Javascript, Typescript, Ruby, SQL...
- Symlink `default-packages` to $NVM_DIR in install script so global packages (mostly language servers) can be used on different versions of Node.
- PHP installation (xml and mbstring libs both needed)
- Code interpretation through a Dockerfile would be awesome, but may not be possible
- null-ls.nvim looks interesting but I don't know use cases for why NVim would need to be an LSP server (add JA config if adding)
- linter plugin support?
- tpope's projectionist plugin looks helpful for dedicated frameworks (e.g. laravel, symfony); setup with JA as reference if adding

