local profile = require('user.profile')

--[[
-- Core
--]]
local plugins = {
  'christoomey/vim-tmux-navigator', -- Cntl-j/k/h/l to move
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('user.plugins.nvim-tree')
    end,
  },
  {
    'voldikss/vim-floaterm',
    config = function()
      require('user.plugins.floaterm')
    end,
    build = function()
      -- Devs left deprecated health calls, so we delete the Vim-specific file that calls those
      local healthfile = vim.fn.stdpath('data') .. '/lazy/vim-floaterm/autoload/health/floaterm.vim'
      if vim.fn.filereadable(healthfile) == 1 then
        vim.fn.delete(healthfile)
      end
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'BurntSushi/ripgrep' },
      { 'kyazdani42/nvim-web-devicons' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      { 'nvim-telescope/telescope-live-grep-args.nvim' },
    },
    config = function()
      require('user.plugins.telescope')
    end,
  },
  -- Rename in a popup window
  {
    'hood/popui.nvim',
    dependencies = 'RishabhRD/popfix',
    config = function()
      vim.ui.select = require('popui.ui-overrider')
      vim.ui.input = require('popui.input-overrider')
    end,
  },
  'farmergreg/vim-lastplace',
  {
    'airblade/vim-rooter',
    -- Only set project root on initial load
    init = function()
      vim.g.rooter_manual_only = 1
    end,
    config = function()
      vim.cmd('Rooter')
    end,
  }, -- Set file search, etc based on current project root
  'sickill/vim-pasta', -- Smart-indent pasting
  --[[
  --End core
  --]]

  -- [[
  -- Code -- Lang, syntax, parsing, code quality and tooling
  -- ]]
  {
    'sheerun/vim-polyglot',
    -- Avoid E741 (locked g:loaded_sleuth): let the real vim-sleuth own indent
    -- detection instead of polyglot's bundled copy (keyed 'autoindent' upstream).
    init = function()
      vim.g.polyglot_disabled = { 'autoindent' }
    end,
  },
  'tpope/vim-sleuth',
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    dependencies = {
      { 'nvim-treesitter/playground', branch = 'master' },
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'master' },
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
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'folke/lsp-colors.nvim',
    },
    config = function()
      require('user.plugins.lspconfig')
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-nvim-lua',
      'onsails/lspkind-nvim',
      'saadparwaiz1/cmp_luasnip',
      {
        'L3MON4D3/LuaSnip',
        config = function()
          require('user.plugins.luasnip')
        end,
      },
    },
    config = function()
      require('user.plugins.cmp')
    end,
  },
  {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end,
  },
  {
    'tpope/vim-fugitive',
    dependencies = 'tpope/vim-rhubarb',
    cmd = 'G',
  },
  --[[
  -- End Code
  --]]

  --[[
  -- Keybindings
  -- TODO: load on keymaps
  --]]
  'tpope/vim-commentary',
  'tpope/vim-surround',
  'nelstrom/vim-visual-star-search', -- hit star to search for word in file
  {
    'karb94/neoscroll.nvim',
    config = function()
      require('neoscroll').setup()
    end,
  },
  {
    'famiu/bufdelete.nvim',
    config = function()
      vim.keymap.set('n', '<Leader>q', ':Bdelete<CR>')
    end,
  },
  {
    'AndrewRadev/splitjoin.vim',
    config = function()
      vim.g.splitjoin_html_attributes_bracket_on_new_line = 1
      vim.g.splitjoin_trailing_comma = 1
      vim.g.splitjoin_php_method_chain_full = 1
    end,
  }, -- split/join lines gS/gJ
  --[[
  --End keybindings
  --]]

  --[[
  -- Extras
  --]]
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('user.plugins.dashboard')
    end,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  --[[
  --End Extras
  --]]
}

--[[
-- Desktop-only extras (skipped on the tty profile)
--]]
if not profile.is_tty() then
  vim.list_extend(plugins, {
    {
      'rebelot/kanagawa.nvim',
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd('colorscheme kanagawa')
        vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#30323E' })
        vim.api.nvim_set_hl(0, 'IndentBlanklineChar', { fg = '#2F313C' })
      end,
    },
    {
      'nvim-lualine/lualine.nvim',
      dependencies = 'kyazdani42/nvim-web-devicons',
      config = function()
        require('user.plugins.lualine')
      end,
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      config = function()
        require('user.plugins.indent-blankline')
      end,
    },
    {
      'folke/trouble.nvim',
      dependencies = 'kyazdani42/nvim-web-devicons',
      config = function()
        require('trouble').setup()
      end,
    },
    {
      'danymat/neogen',
      config = function()
        require('neogen').setup({})
      end,
      dependencies = 'nvim-treesitter/nvim-treesitter',
    }, -- Generates annotations with :Neogen: TODO: load on command
    {
      'lewis6991/gitsigns.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
      config = function()
        require('user.plugins.gitsigns')
      end,
    },
    {
      'lervag/vimtex',
      config = function()
        require('user.plugins.vimtex')
      end,
    }, -- TODO: load on filetype (.tex?))
  })
end

return plugins
