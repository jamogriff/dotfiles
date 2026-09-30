-- nvim-treesitter `main` only installs parsers and queries; highlighting,
-- folding and indent are Neovim built-ins that have to be switched on per
-- buffer (see the FileType autocmd below). Installing needs the tree-sitter
-- CLI (src/install-nvim puts it on PATH) and a C compiler.
require('nvim-treesitter').install({ 'php', 'lua', 'javascript', 'ruby', 'python' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user_treesitter', { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    -- Not every filetype has a parser (NvimTree, floaterm, ...): leave those alone.
    if not lang or not pcall(vim.treesitter.start, args.buf, lang) then
      return
    end

    if vim.treesitter.query.get(lang, 'indents') then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require('nvim-treesitter-textobjects').setup({
  select = {
    lookahead = true,
  },
})

local select_textobjects = {
  ['if'] = '@function.inner',
  ['af'] = '@function.outer',
  ['ic'] = '@class.inner',
  ['ac'] = '@class.outer',
  ['ia'] = '@parameter.inner',
  ['aa'] = '@parameter.outer',
}

for lhs, capture in pairs(select_textobjects) do
  vim.keymap.set({ 'x', 'o' }, lhs, function()
    require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
  end)
end
