local status_ok, config = pcall(require, 'ibl')

if not status_ok then
  vim.notify('Indent Breakline unable to be loaded!', vim.log.levels.WARN)
  return
end

config.setup({
    exclude = {
      filetypes = {
        'help',
        'terminal',
        'dashboard',
        'packer',
        'lspinfo',
        'TelescopePrompt',
        'TelescopeResults',
      },
      buftypes = {
        'terminal',
        'NvimTree',
      }
    },
})
