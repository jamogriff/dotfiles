vim.api.nvim_create_user_command("ZenDoc", function()
  local main_win = vim.api.nvim_get_current_win()

  local function apply_center_opts(win)
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].wrap = true
      vim.wo[win].linebreak = true
    end
  end

  -- Helper to configure the blank padding windows
  local function setup_padding(side)
    vim.cmd("vertical resize 20")
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false

    -- Buffer-local scratch options to prevent nvim-tree conflicts
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buflisted = false
    vim.bo[buf].swapfile = false

    -- Give the buffer a unique name so nvim-tree won't collide with it
    pcall(vim.api.nvim_buf_set_name, buf, "ZenDoc_" .. side .. "Pad_" .. buf)
  end

  vim.cmd("topleft vnew")
  setup_padding("Left")

  vim.cmd("botright vnew")
  setup_padding("Right")

  -- Return focus to the main file and apply settings
  vim.api.nvim_set_current_win(main_win)
  apply_center_opts(main_win)

  -- Create a dedicated augroup for this centered window
  local group = vim.api.nvim_create_augroup("ZenDoc_" .. main_win, { clear = true })

  -- Re-apply settings whenever a new file/buffer is opened in the center window
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() == main_win then
        apply_center_opts(main_win)
      end
    end,
  })

  -- Clean up the autocommand automatically if the center window is closed
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(main_win),
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end, {})

