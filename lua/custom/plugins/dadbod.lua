return {
  {
    'tpope/vim-dadbod',
    cmd = 'DB',
    lazy = false,
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      'tpope/vim-dadbod',
    },
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    keys = {
      { '<leader>db', '<cmd>DBUIToggle<cr>', desc = 'Toggle Dadbod UI' },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.dbs = {
        {
          name = 'DevOpsReporting',
          url = 'sqlserver://sa:%21MySecretTemplafyPassword1@127.0.0.1:1433/DevOpsReporting?trustServerCertificate=true',
        },
      }

      -- Show current row vertically in a popup
      vim.keymap.set('n', '<leader>dv', function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        if #lines < 2 then return end

        -- Find header line (first non-empty line with column separators)
        local header_line, header_idx
        for i, line in ipairs(lines) do
          if line:match('%S') and not line:match('^%s*%-+') then
            header_line = line
            header_idx = i
            break
          end
        end
        if not header_line then return end

        -- Parse headers
        local headers = {}
        for col in header_line:gmatch('%S+') do
          table.insert(headers, col)
        end

        -- Get current line
        local cur_line = vim.api.nvim_get_current_line()
        if cur_line:match('^%s*%-+') or cur_line == header_line then
          vim.notify('Move cursor to a data row', vim.log.levels.WARN)
          return
        end

        -- Parse values
        local values = {}
        for val in cur_line:gmatch('%S+') do
          table.insert(values, val)
        end

        -- Build vertical display
        local display = {}
        local max_header_len = 0
        for _, h in ipairs(headers) do
          max_header_len = math.max(max_header_len, #h)
        end
        for i, header in ipairs(headers) do
          local val = values[i] or 'NULL'
          table.insert(display, string.format('%-' .. max_header_len .. 's : %s', header, val))
        end

        -- Show in floating window
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, display)
        local width = math.min(80, math.max(40, max_header_len + 50))
        local height = math.min(#display, 30)
        vim.api.nvim_open_win(buf, true, {
          relative = 'cursor',
          row = 1,
          col = 0,
          width = width,
          height = height,
          style = 'minimal',
          border = 'rounded',
        })
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf })
        vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf })
      end, { desc = 'Show DB row vertically' })
    end,
  },
  {
    'kristijanhusak/vim-dadbod-completion',
    dependencies = {
      'tpope/vim-dadbod',
    },
    ft = { 'sql', 'mysql', 'plsql' },
  },
}
