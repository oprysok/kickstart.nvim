return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local function truncate_branch_name()
      local branch = vim.b.gitsigns_head or ''
      local max_length = 25 -- Set the max length for the branch name
      if #branch > max_length then
        return branch:sub(1, max_length) .. '…' -- Truncate and add an ellipsis
      end
      return branch
    end

    require('lualine').setup {
      options = {
        theme = 'dracula',
      },
      sections = {
        lualine_b = { { 'branch', icon = '', fmt = truncate_branch_name } }, -- Truncate branch name
        lualine_c = { { 'filename', path = 1 } }, -- Show relative file path
      },
    }
  end,
}
