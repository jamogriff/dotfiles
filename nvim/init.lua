vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('user.lazy')

if require('user.profile').is_tty() then
  vim.cmd.colorscheme('desert')
end

require('user.options')
require('user.keymaps')
