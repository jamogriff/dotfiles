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

-- Theme
use({
  'rebelot/kanagawa.nvim',
  config = function()
    vim.cmd('colorscheme kanagawa')

    -- Hide the characters in FloatBorder
    -- vim.api.nvim_set_hl(0, 'FloatBorder', {
    --   fg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
    --   bg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
    -- })

    -- -- Make the StatusLineNonText background the same as StatusLine
    -- vim.api.nvim_set_hl(0, 'StatusLineNonText', {
    --   fg = vim.api.nvim_get_hl_by_name('NonText', true).foreground,
    --   bg = vim.api.nvim_get_hl_by_name('StatusLine', true).background,
    -- })

    -- -- Hide the characters in CursorLineBg
    -- vim.api.nvim_set_hl(0, 'CursorLineBg', {
    --   fg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
    --   bg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
    -- })

    -- vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#30323E' })
    -- vim.api.nvim_set_hl(0, 'IndentBlanklineChar', { fg = '#2F313C' })
  end,
})

use('tpope/vim-commentary')
use('tpope/vim-surround')
use('tpope/vim-eunuch') -- Useful Unix commands like :Rename and :SudoWrite
use('tpope/vim-unimpaired') -- Pairs of handy bracket mappings [b or ]b
use('tpope/vim-sleuth') -- Smart auto-indentation with editorconfig support
use('tpope/vim-repeat')
use('sheerun/vim-polyglot')
use('christoomey/vim-tmux-navigator') -- Cntl-j/k/h/l to move
use('farmergreg/vim-lastplace')
use('nelstrom/vim-visual-star-search')
use('jessarcher/vim-heritage')
use({
  'whatyouhide/vim-textobj-xmlattr',
  requires = 'kana/vim-textobj-user',
}) -- ix and ax motions for HTML attr
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
use({
  'windwp/nvim-autopairs',
  config = function()
    require('nvim-autopairs').setup()
  end,
})
use('karb94/neoscroll.nvim')
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
})
use('sickill/vim-pasta')
use({
  'lukas-reineke/indent-blankline.nvim',
  -- config = function()
  --   require('user.plugins.indent-blankline')
  -- end,
})
use({
  'akinsho/bufferline.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  after = 'kanagawa.nvim',
  -- config = function()
  --   require('user.plugins.bufferline')
  -- end,
})
use({
  'nvim-lualine/lualine.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  -- config = function()
  --   require('user.plugins.lualine')
  -- end,
})
use({
  'kyazdani42/nvim-tree.lua',
  requires = 'kyazdani42/nvim-web-devicons',
  -- config = function()
  --   require('user.plugins.nvim-tree')
  -- end,
})
use({
  'vim-test/vim-test',
  -- config = function()
  --   require('user.plugins.vim-test')
  -- end,
})

use({
  'voldikss/vim-floaterm',
  -- config = function()
  --   require('user.plugins.floaterm')
  -- end,
})

use({
  'nvim-telescope/telescope.nvim',
  requires = {
    { 'nvim-lua/plenary.nvim' },
    { 'kyazdani42/nvim-web-devicons' },
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    { 'nvim-telescope/telescope-live-grep-args.nvim' },
  },
  -- config = function()
  --   require('user.plugins.telescope')
  -- end,
})
-- TODO Someday get into this
-- use({
--   'nvim-treesitter/nvim-treesitter',
--   run = ':TSUpdate',
--   requires = {
--     'nvim-treesitter/playground',
--     'nvim-treesitter/nvim-treesitter-textobjects',
--     'JoosepAlviste/nvim-ts-context-commentstring',
--   },
--   config = function()
--     require('user.plugins.treesitter')
--   end,
-- })
use({
  'tpope/vim-fugitive',
  requires = 'tpope/vim-rhubarb',
  cmd = 'G',
})

use({
  'lewis6991/gitsigns.nvim',
  requires = 'nvim-lua/plenary.nvim',
  config = function()
    require('gitsigns').setup({
      sign_priority = 20,
      on_attach = function(bufnr)
        vim.keymap.set('n', ']h', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true, buffer = bufnr })
        vim.keymap.set('n', '[h', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true, buffer = bufnr })
      end,
    })
  end,
})
use({
  'neovim/nvim-lspconfig',
  requires = {
    'folke/lsp-colors.nvim',
  },
  -- config = function()
  --   require('user.plugins.lspconfig')
  -- end,
})
-- TODO both of these are used for auto-completion
-- use({
--   'L3MON4D3/LuaSnip',
--   config = function()
--     require('user.plugins.luasnip')
--   end,
-- })

-- use({
--   'hrsh7th/nvim-cmp',
--   requires = {
--     'L3MON4D3/LuaSnip',
--     'hrsh7th/cmp-buffer',
--     'hrsh7th/cmp-cmdline',
--     'hrsh7th/cmp-nvim-lsp',
--     'hrsh7th/cmp-nvim-lsp-signature-help',
--     'hrsh7th/cmp-nvim-lua',
--     'jessarcher/cmp-path',
--     'onsails/lspkind-nvim',
--     'saadparwaiz1/cmp_luasnip',
--   },
--   config = function()
--     require('user.plugins.cmp')
--   end,
-- })
use({
  'phpactor/phpactor',
  branch = 'master',
  ft = 'php',
  run = 'composer install --no-dev -o',
  -- config = function()
  --   require('user.plugins.phpactor')
  -- end,
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

use({
  'folke/trouble.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  -- config = function()
  --   require('trouble').setup()
  -- end,
})
-- TODO treesitter needed
-- use({
--   'danymat/neogen',
--   config = function()
--     require('neogen').setup({})
--   end,
--   requires = 'nvim-treesitter/nvim-treesitter',
-- })
use({
  'glepnir/dashboard-nvim',
  -- config = function()
  --   require('user.plugins.dashboard')
  -- end,
})
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
