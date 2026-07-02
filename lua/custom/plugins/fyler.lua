-- Fyler: file explorer. nvim-web-devicons is provided by mini.icons' mock (see init.lua)
vim.pack.add { { src = 'https://github.com/A7Lavinraj/fyler.nvim' } }

---@module 'fyler'
---@type FylerSetupOptions
require('fyler').setup {
  integrations = { icon = 'nvim_web_devicons' },
  views = {
    finder = {
      columns = {
        permission = { enabled = false },
        size = { enabled = false },
      },
      win = {
        kinds = {
          split_left_most = {
            width = '20%',
          },
        },
        win_opts = {
          foldcolumn = '2',
        },
      },
    },
  },
}
