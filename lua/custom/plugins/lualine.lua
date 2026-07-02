-- Statusline. nvim-web-devicons is provided by mini.icons' mock (see init.lua)
vim.pack.add { { src = 'https://github.com/nvim-lualine/lualine.nvim' } }

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
    theme = 'ayu_dark',
  },
  sections = {
    lualine_b = { { 'branch', icon = '', fmt = truncate_branch_name } }, -- Truncate branch name
    lualine_c = { { 'filename', path = 1 } }, -- Show relative file path
  },
}
