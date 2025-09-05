local separator = { '"▕"', color = 'StatusLineNonText' }

require('lualine').setup({
  options = {
    section_separators = '',
    component_separators = '',
    globalstatus = true,
    theme = {
      normal = {
        a = 'StatusLine',
        b = 'StatusLine',
        c = 'StatusLine',
      },
    },
  },
  sections = {
    lualine_a = {
      'mode',
    },
    lualine_b = {
      'branch',
      'diff',
    },
    lualine_c = {
      separator,
      {
        'filename',
        path = 1
      },
    },
    lualine_x = {
      '"🖧  " .. tostring(#vim.tbl_keys(vim.lsp.get_clients()))',
      {
        'diagnostics',
        sources = {'nvim_diagnostic'},
        sections = {'error', 'warn'},
        symbols = {error = '', warn = ''},
      },
      separator
    },
    lualine_y = {
      'filetype',
    },
    lualine_z = {
      'location',
    },
  },
})
