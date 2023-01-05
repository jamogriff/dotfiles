-- Install packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Initialize packer
require('packer').init({
  compile_path = vim.fn.stdpath('data')..'/site/plugin/packer_compiled.lua',
--  display = {
--    open_fn = function()
--      return require('packer.util').float({ border = 'solid' })
--    end,
--  },
})

-- Install plugins
local use = require('packer').use

-- Packer can manage itself
use('wbthomason/packer.nvim')

-- Comment support (gcc)
use('tpope/vim-commentary')

-- Add, change, delete surrounding text (cs)
use('tpope/vim-surround')

-- Useful Unix commands like :Rename and :SudoWrite
use('tpope/vim-eunuch')

-- Pairs of handy bracket mappings [b or ]b
use('tpope/vim-unimpaired')

-- Smart auto-indentation with editorconfig support
use('tpope/vim-sleuth')

--  Allow plugins to hook into . repeat behavior
use('tpope/vim-repeat')

-- Add more languages
use('sheerun/vim-polyglot')

-- Navigate between splits and Tmux panes using same key-bindings
use('christoomey/vim-tmux-navigator')

-- Jump to last location when opening a file
use('farmergreg/vim-lastplace')

-- Adds * search functionality to visual selection
use('nelstrom/vim-visual-star-search')

-- Automatically create parent dirs on file save
use('jessarcher/vim-heritage')

-- Adds html attribute text objects
use({
  'whatyouhide/vim-textobj-xmlattr',
  requires = 'kana/vim-textobj-user',
})

-- Set file search, etc based on current project root
use({
  'airblade/vim-rooter',
  -- Only set project root on initial load
  setup = function()
    vim.g.rooter_manual_only = 1
  end,
  config = function()
    vim.cmd('Rooter')
  end,
})

-- Creates automatic closing (, {, ', etc)
use({
  'windwp/nvim-autopairs',
  config = function()
    require('nvim-autopairs').setup()
  end,
})

-- Smoother scroll
use('karb94/neoscroll.nvim')

-- Leave split open after closing buffer
use({
  'famiu/bufdelete.nvim',
  config = function()
    vim.keymap.set('n', '<Leader>q', ':Bdelete<CR>')
  end,
})
-- Easily expand and collapse arrays, etc
use({
  'AndrewRadev/splitjoin.vim',
  config = function()
    vim.g.splitjoin_html_attributes_bracket_on_new_line = 1
    vim.g.splitjoin_trailing_comma = 1
    vim.g.splitjoin_php_method_chain_full = 1
  end,
})

-- Better pasting indentation
use('sickill/vim-pasta')

-- Automatically set up your configuration after cloning packer.nvim
-- Put this at the end after all plugins
if packer_bootstrap then
	require('packer').sync()
end

-- Compile when there's a change made in plugins.lua
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile>
  augroup end
]])
