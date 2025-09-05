vim.keymap.set('n', '<Leader>1', ':FloatermToggle scratch<CR>')
vim.keymap.set('t', '<Leader>1', '<C-\\><C-n>:FloatermToggle scratch<CR>')

vim.g.floaterm_width = 0.6
vim.g.floaterm_height = 0.6
vim.g.floaterm_title = "Terminal"

vim.cmd([[
  highlight link Floaterm CursorLine
  highlight link FloatermBorder CursorLineBg
]])
