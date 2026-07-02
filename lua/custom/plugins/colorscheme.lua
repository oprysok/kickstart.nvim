-- Colorscheme: ayu-dark (overrides the tokyonight set in init.lua)
vim.pack.add { { src = 'https://github.com/Shatur/neovim-ayu' } }
require('ayu').setup {
  mirage = false,
}
vim.cmd.colorscheme 'ayu-dark'
