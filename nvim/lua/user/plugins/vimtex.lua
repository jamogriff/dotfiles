vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_compiler_method = 'latexmk'

-- Configure latexmk to use lualatex
vim.g.vimtex_compiler_latexmk = {
  build_dir = '',
  callback = 1,
  continuous = 1,
  executable = 'latexmk',
  options = {
    '-pdf',
    '-pdflatex=lualatex',
    '-file-line-error',
    '-synctex=1',
    '-interaction=nonstopmode',
  },
}
