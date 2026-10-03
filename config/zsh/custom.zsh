typeset -U path

# Homebrew, on macOS only; neither prefix exists on Linux. Before the PATH
# line so ~/.local/bin still ends up ahead of brew's bin.
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$brew" ] && eval "$("$brew" shellenv)" && break
done
unset brew

path=("$HOME/.local/bin" $path)

# Good good color
export TERM=xterm-256color

# Personal aliases.
alias vim='nvim'

# Sources our dotfiles .env file
if [ -f $HOME/.env ]; then
    source $HOME/.env
else
    echo 'WARNING: No .env file found'
fi
