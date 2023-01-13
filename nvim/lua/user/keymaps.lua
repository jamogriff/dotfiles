vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Easy escape
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('i', 'kj', '<Esc>')

-- When text is wrapped, move by terminal rows, not lines, unless a count is provided
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Reselect visual selection after indenting
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', '<', '<gv')

-- Keep cursor in place after yanking visual selection
vim.keymap.set('v', 'y', 'myy`y')

-- Disable annoying command history (usually type this by mistake)
vim.keymap.set('n', 'q:', ':q')

-- Paste replace visual selection without copying it (YES!)
vim.keymap.set('v', 'p', '"_dP')

-- Easy insertion of ; or , at EoL
vim.keymap.set('i', ';;', '<Esc>A;')
vim.keymap.set('i', ',,', '<Esc>A,')

-- Shortcut to disable search highlighting
vim.keymap.set('n', '<Leader>k', ':nohlsearch<CR>')

-- Open current file in default OS program
vim.keymap.set('n', '<Leader>o', ':!xdg-open %<CR><CR>')

-- Handy switch lines with each other
vim.keymap.set('i', '<A-j>', '<Esc>:move .+1<CR>==gi')
vim.keymap.set('i', '<A-k>', '<Esc>:move .-2<CR>==gi')
vim.keymap.set('n', '<A-j>', ':move .+1<CR>==')
vim.keymap.set('n', '<A-k>', ':move .-2<CR>==')
-- These don't work for some reason
--vim.keymap.set('v', '<A-j>', ':move >+1<CR>gv=gv')
--vim.keymap.set('v', '<A-k>', ':move <-2<CR>gv=gv')

-- Resize with arrow keys
vim.keymap.set('n', '<C-Up>', ':resize +2<CR>')
vim.keymap.set('n', '<C-Down>', ':resize -2<CR>')
vim.keymap.set('n', '<C-Left>', ':vertical resize -2<CR>')
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>')
