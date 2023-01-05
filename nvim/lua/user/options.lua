vim.opt.expandtab = true
vim.opt.shiftwidth=4
vim.opt.tabstop=4
vim.opt.softtabstop=4

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true

-- search options
vim.opt.wildmode = 'longest:full,full' -- complete longest common match; allow tabbing to complete results
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.title = true
vim.opt.mouse = 'a' -- allow for mouse scroll

vim.opt.termguicolors = true

vim.opt.spell = true

vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '·' }
vim.opt.fillchars:append({ eob = ' ' }) -- remove ~ from end of buffer

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.clipboard = 'unnamedplus'

vim.opt.confirm = true -- ask for file save confirmation instead of error

vim.opt.undofile = true -- persistent undo
vim.opt.backup = true -- automatically save backup file
vim.opt.backupdir:remove('.') -- keep backup files out of current dir
--" Some basics:
--	set encoding=utf-8
--	set noshowmode
--	syntax on
--	imap jk <Esc>
--	imap kj <Esc>
--
--" Tabs/spaces:
--	filetype indent plugin on
--	set autoindent " Indent next line
