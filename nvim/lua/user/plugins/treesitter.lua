local config = require('nvim-treesitter.configs')

config.setup({
  ensure_installed = { "php", "lua", "javascript", "ruby" },
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = false,
  highlight = {
    enable = true,
    disable = { 'NvimTree' },
    additional_vim_regex_highlighting = false, -- this may slow down vim
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["if"] = "@function.inner",
        ["af"] = "@function.outer",
        ["ic"] = "@class.inner",
        ["ac"] = "@class.outer",
        ['ia'] = '@parameter.inner',
        ['aa'] = '@parameter.outer',
      },
    },
  },
  context_commentstring = {
    enable = true,
  },
})
