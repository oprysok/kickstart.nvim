-- JavaScript / TypeScript indentation settings
-- This is what is used even before triggering conform.nvim (format on save)
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Set 2-space indentation for TypeScript files',
  group = vim.api.nvim_create_augroup('typescript-indent', { clear = true }),
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.expandtab = true
  end,
});

-- vim.api.nvim_create_autocmd('BufWritePre', {
--   buffer = bufnr,
--   command = 'EslintFixAll',
-- })

return {}