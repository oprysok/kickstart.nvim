-- return {
--   'catppuccin/nvim',
--   name = 'catppuccin',
--   priority = 999,
--   config = function()
--     vim.cmd.colorscheme 'catppuccin-mocha'
--   end,
-- }

return {
  'Shatur/neovim-ayu',
  name = 'ayu',
  priority = 1000,
  config = function()
    require('ayu').setup({
      mirage = false,
    })
    vim.cmd.colorscheme 'ayu-dark'
  end,
}
