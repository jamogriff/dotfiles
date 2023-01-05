vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- When text is wrapped, move by terminal rows, not lines, unless a count is provided
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })
-- When text is wrapped, move by terminal rows, not lines, unless a count is provided-- When text is wrapped, move by terminal rows, not lines, unless a count is provided-- When text is wrapped, move by terminal rows, not lines, unless a count is provided-- When text is wrapped, move by terminal rows, not lines, unless a count is provided-- When text is wrapped, move by terminal rows, not lines, unless a count is provided
