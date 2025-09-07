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
})

-- Install plugins
local use = require('packer').use

-- Packer can manage itself
use('wbthomason/packer.nvim')

--[[
-- Core
--]]
--
-- Theme
use({
  'rebelot/kanagawa.nvim',
  config = function()
    vim.cmd('colorscheme kanagawa')
    vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#30323E' })
    vim.api.nvim_set_hl(0, 'IndentBlanklineChar', { fg = '#2F313C' })
  end,
})
use('christoomey/vim-tmux-navigator') -- Cntl-j/k/h/l to move
use({
  'nvim-lualine/lualine.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('user.plugins.lualine')
  end,
})
use({
  'kyazdani42/nvim-tree.lua',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('user.plugins.nvim-tree')
  end,
})
use({
  'voldikss/vim-floaterm',
  config = function()
    require('user.plugins.floaterm')
  end,
  run = function()
    -- Devs left deprecated health calls, so we delete the Vim-specific file that calls those
    local healthfile = vim.fn.stdpath("data") .. "/site/pack/packer/start/vim-floaterm/autoload/health/floaterm.vim"
    if vim.fn.filereadable(healthfile) == 1 then
      vim.fn.delete(healthfile)
    end
  end,
})
use({
  'nvim-telescope/telescope.nvim',
  after = 'kanagawa.nvim',
  requires = {
    { 'nvim-lua/plenary.nvim' },
    { 'BurntSushi/ripgrep'},
    { 'kyazdani42/nvim-web-devicons' },
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    { 'nvim-telescope/telescope-live-grep-args.nvim' },
  },
  config = function()
    require('user.plugins.telescope')
  end,
})
-- Rename in a popup window
use({
  'hood/popui.nvim',
  requires = 'RishabhRD/popfix',
  config = function()
    vim.ui.select = require('popui.ui-overrider')
    vim.ui.input = require('popui.input-overrider')
  end,
})
use('farmergreg/vim-lastplace')
use({
  'airblade/vim-rooter',
  -- Only set project root on initial load
  setup = function()
    vim.g.rooter_manual_only = 1
  end,
  config = function()
    vim.cmd('Rooter')
  end,
}) -- Set file search, etc based on current project root
use('sickill/vim-pasta') -- Smart-indent pasting
--[[
--End core
--]]

-- [[
-- Code -- Lang, syntax, parsing, code quality and tooling
-- ]]
use('sheerun/vim-polyglot')
use('tpope/vim-sleuth')
use({
  'lukas-reineke/indent-blankline.nvim',
  config = function()
    require('user.plugins.indent-blankline')
  end,
})
use({
  'nvim-treesitter/nvim-treesitter',
  run = function()
    local ts_install = require('nvim-treesitter.install')
    if ts_install then
      ts_install.update({ with_sync = true })
    end
  end,
  requires = {
    'nvim-treesitter/playground',
    'nvim-treesitter/nvim-treesitter-textobjects',
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    -- Skip loading deprecated module
    vim.g.skip_ts_context_commentstring_module = true

    -- Use updated interface and
    -- disable autocmd-based updates if not needed
    require('ts_context_commentstring').setup({
        enable_autocmd = false,
    })
    require('user.plugins.treesitter')
  end,
})
use({
  'neovim/nvim-lspconfig',
  requires = {
    'folke/lsp-colors.nvim',
  },
  config = function()
    require('user.plugins.lspconfig')
  end,
})
use({
  'hrsh7th/nvim-cmp',
  requires = {
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lsp-signature-help',
    'hrsh7th/cmp-nvim-lua',
    'onsails/lspkind-nvim',
  },
  config = function()
    require('user.plugins.cmp')
  end,
})
use({
  'folke/trouble.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('trouble').setup()
  end,
})
use({
  'windwp/nvim-autopairs',
  config = function()
    require('nvim-autopairs').setup()
  end,
})
use({
  'danymat/neogen',
  config = function()
    require('neogen').setup({})
  end,
  requires = 'nvim-treesitter/nvim-treesitter',
}) -- Generates annotations with :Neogen: TODO: load on command
use({
  'tpope/vim-fugitive',
  requires = 'tpope/vim-rhubarb',
  cmd = 'G',
})
use({
  'lewis6991/gitsigns.nvim',
  requires = 'nvim-lua/plenary.nvim',
  config = function()
    require('user.plugins.gitsigns')
  end,
})
--[[
-- End Code
--]]

--[[
-- Keybindings
-- TODO: load on keymaps
--]]
use('tpope/vim-commentary')
use('tpope/vim-surround')
use('nelstrom/vim-visual-star-search') -- hit star to search for word in file
use({
  'karb94/neoscroll.nvim',
  config = function()
    require('neoscroll').setup()
  end,
})
use({
  'famiu/bufdelete.nvim',
  config = function()
    vim.keymap.set('n', '<Leader>q', ':Bdelete<CR>')
  end,
})
use({
  'AndrewRadev/splitjoin.vim',
  config = function()
    vim.g.splitjoin_html_attributes_bracket_on_new_line = 1
    vim.g.splitjoin_trailing_comma = 1
    vim.g.splitjoin_php_method_chain_full = 1
  end,
}) -- split/join lines gS/gJ
--[[
--End keybindings
--]]

--[[
-- Extras
--]]
use({
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('user.plugins.dashboard')
  end,
  requires = {'nvim-tree/nvim-web-devicons'},
})
use({
  'lervag/vimtex',
  config = function()
    require('user.plugins.vimtex')
  end,
})-- TODO: load on filetype (.tex?))
--[[
--End Extras
--]]

-- Automatically install plugins on initial run
if packer_bootstrap then
  require('packer').sync()
end

-- Automatically regenerate compiled loader file on save
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile>
  augroup end
]])
