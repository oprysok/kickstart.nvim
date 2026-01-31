-- Filetypes to exclude from session
local excluded_filetypes = { 'fyler', 'dbui', 'dbout' }

local function close_excluded_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ft = vim.bo[buf].filetype
      local bufname = vim.api.nvim_buf_get_name(buf)
      -- Check filetype or if it's a dadbod buffer
      if vim.tbl_contains(excluded_filetypes, ft)
        or bufname:match('^dbui://')
        or bufname:match('/db_ui/') then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end
end

-- Close excluded buffers before saving session
vim.api.nvim_create_autocmd('VimLeavePre', {
  desc = 'Close excluded buffers before session save',
  group = vim.api.nvim_create_augroup('kickstart-close-excluded-bufs', { clear = true }),
  callback = close_excluded_buffers,
})

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Auto load last session if it exists',
  group = vim.api.nvim_create_augroup('kickstart-auto-load-persistence', { clear = true }),
  callback = function()
    local persistence = require 'persistence'
    persistence.load()
  end,
  nested = true,
})

return {
  'folke/persistence.nvim',
  event = 'BufReadPre', -- this will only start session saving when an actual file was opened
  opts = {
    dir = vim.fn.stdpath 'state' .. '/sessions/', -- directory where session files are saved
    -- minimum number of file buffers that need to be open to save
    -- Set to 0 to always save
    need = 0,
    branch = false, -- use git branch to save session
    pre_save = close_excluded_buffers,
  },
}

