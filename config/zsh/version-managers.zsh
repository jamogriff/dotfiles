# Version managers + ~/.local/bin, for zsh.
#
# The nvm/rbenv/uv installers each write their init snippet to the rc file they
# auto-detect — always ~/.bashrc, since `dotfiles bootstrap` runs under bash — so
# none of them reach zsh, which is the shell setup/zsh then makes the default.
# Steering them at zsh instead is unreliable: rbenv derives the shell from
# `ps -p $PPID` and overwrites what you pass it, and nvm honors $PROFILE only if
# that file already exists, which ~/.zshrc doesn't yet.
#
# Keep this in sync with whatever the installers write into ~/.bashrc.

# ~/.local/bin holds nvim, the `t` script, and uv/uvx. uv puts this PATH line in
# ~/.profile, which zsh never reads.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# nvm. Its completion script is written in bash and calls `complete`, which fails
# silently under plain zsh; oh-my-zsh has already run compinit by now, so
# bashcompinit is all that's missing.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -s "$NVM_DIR/bash_completion" ]; then
  autoload -U +X bashcompinit && bashcompinit
  . "$NVM_DIR/bash_completion"
fi

# rbenv. --no-rehash keeps shell startup fast; run `rbenv rehash` by hand after
# installing a gem that ships a binary.
[ -x "$HOME/.rbenv/bin/rbenv" ] && eval "$("$HOME/.rbenv/bin/rbenv" init - --no-rehash zsh)"
