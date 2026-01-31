-- return {
--   'catppuccin/nvim',
--   name = 'catppuccin',
--   priority = 999,
--   config = function()
--     vim.cmd.colorscheme 'catppuccin-mocha'
--   end,
-- }

return {
  'bluz71/vim-moonfly-colors',
  name = 'moonfly',
  priority = 1001,
  config = function()
    vim.cmd.colorscheme 'moonfly'
  end,
}
