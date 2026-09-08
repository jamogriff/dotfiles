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
