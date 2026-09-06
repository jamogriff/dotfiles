-- Which install profile this machine was set up with: 'desktop' (full plugin set)
-- or 'tty' (lighter set for a bare Linux console). Set by setup/desktop/config
-- and setup/tty/config via ~/.dotfiles-profile.
local M = {}

local profile_file = os.getenv('HOME') .. '/.dotfiles-profile'

function M.get()
  local f = io.open(profile_file, 'r')
  if not f then
    return 'desktop'
  end

  local contents = f:read('*l')
  f:close()

  return contents == 'tty' and 'tty' or 'desktop'
end

function M.is_tty()
  return M.get() == 'tty'
end

return M
