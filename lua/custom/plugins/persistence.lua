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
  },
}

