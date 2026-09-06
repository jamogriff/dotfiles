# Version managers + ~/.local/bin, for zsh.
#
# The nvm/rbenv/uv installers in setup/desktop/bootstrap-languages each append their own
# init snippet to a single rc file that they auto-detect. Because `dotfiles bootstrap`
# runs under bash, they all detect bash and write to ~/.bashrc — so none of them are
# available in zsh, which is the shell setup/zsh then makes the default.
#
# Steering the installers at zsh instead is unreliable: rbenv's installer derives
# the shell from `ps -p $PPID` and overwrites anything you pass it, and nvm honors
# $PROFILE only if that file already exists — which ~/.zshrc doesn't yet, since
# setup/desktop/bootstrap-languages runs before setup/zsh. So this file re-declares the
# same initialization for zsh, and setup/desktop/config symlinks it into $ZSH_CUSTOM.
#
# Keep this in sync with whatever the installers write into ~/.bashrc.

# ~/.local/bin holds nvim, the `t` script, and uv/uvx. uv puts the PATH line for it
# in ~/.profile, which zsh never reads — so without this, none of them resolve.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# nvm (Node). The completion script ~/.bashrc gets is written in bash and calls
# `complete`, which plain zsh doesn't have — sourcing it without bashcompinit
# fails silently and registers nothing. oh-my-zsh has already run compinit by the
# time it sources this file, so bashcompinit is all that's missing.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -s "$NVM_DIR/bash_completion" ]; then
  autoload -U +X bashcompinit && bashcompinit
  . "$NVM_DIR/bash_completion"
fi

# rbenv (Ruby). --no-rehash keeps shell startup fast; run `rbenv rehash` by hand
# after installing a gem that ships a binary.
[ -x "$HOME/.rbenv/bin/rbenv" ] && eval "$("$HOME/.rbenv/bin/rbenv" init - --no-rehash zsh)"
