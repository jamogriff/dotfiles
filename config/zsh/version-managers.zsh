# Hooking up version managers
#
# nvm: Its completion script is written in bash and calls `complete`, which fails
# silently under plain zsh; oh-my-zsh has already run compinit by now, so
# bashcompinit is all that's missing.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -s "$NVM_DIR/bash_completion" ]; then
  autoload -U +X bashcompinit && bashcompinit
  . "$NVM_DIR/bash_completion"
fi

# rbenv: --no-rehash keeps shell startup fast; run `rbenv rehash` by hand after
# installing a gem that ships a binary.
[ -x "$HOME/.rbenv/bin/rbenv" ] && eval "$("$HOME/.rbenv/bin/rbenv" init - --no-rehash zsh)"
