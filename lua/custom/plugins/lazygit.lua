-- LazyGit integration. plenary.nvim is already installed by the Telescope section.
vim.pack.add { { src = 'https://github.com/kdheepak/lazygit.nvim' } }

vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'LazyGit' })
