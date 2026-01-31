return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  ---@module 'fyler'
  ---@type FylerSetupOptions
  opts = {
    integrations = { icon = "nvim_web_devicons" },
    views = {
      finder = {
        columns = {
          permission = { enabled = false },
          size = { enabled = false },
        },
        win = {
          kinds = {
            split_left_most = {
              width = "20%",
            },
          },
          win_opts = {
            foldcolumn = "2",
          },
        },
      },
    },
  },
}