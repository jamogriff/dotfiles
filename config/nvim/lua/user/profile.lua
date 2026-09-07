-- Which install profile this machine was set up with: 'desktop' (full plugin
-- set) or 'tty' (lighter set for a bare Linux console). Comes from
-- DOTFILES_PROFILE, which ~/.zshrc exports by sourcing ~/.env.
--
-- Anything but 'tty' means desktop, so a GUI-launched nvim that inherited no
-- environment still gets the full set rather than silently degrading.
local M = {}

function M.get()
  return os.getenv('DOTFILES_PROFILE') == 'tty' and 'tty' or 'desktop'
end

function M.is_tty()
  return M.get() == 'tty'
end

return M
