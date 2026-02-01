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

      local db_url = 'sqlserver://sa:%21MySecretTemplafyPassword1@127.0.0.1:1433/DevOpsReporting?trustServerCertificate=true'

      vim.g.dbs = {
        {
          name = 'DevOpsReporting',
          url = db_url,
        },
      }

      -- Helper: parse dadbod result buffer structure
      local function parse_result_buffer()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        if #lines < 2 then return nil end

        -- Find header and separator lines
        local header_line, separator_line, header_idx
        for i, line in ipairs(lines) do
          if line:match('%S') and not line:match('^%s*%-+%s*%-*') then
            header_line = line
            header_idx = i
            if lines[i + 1] and lines[i + 1]:match('^%s*%-+') then
              separator_line = lines[i + 1]
            end
            break
          end
        end
        if not header_line then return nil end

        -- Detect column boundaries from separator line
        local col_ranges = {}
        if separator_line then
          local pos = 1
          for dashes, spaces in separator_line:gmatch('(%-+)(%s*)') do
            table.insert(col_ranges, { pos, pos + #dashes - 1 })
            pos = pos + #dashes + #spaces
          end
        end

        -- Parse headers
        local headers = {}
        if #col_ranges > 0 then
          for _, range in ipairs(col_ranges) do
            local header = header_line:sub(range[1], range[2]):match('^%s*(.-)%s*$') or ''
            table.insert(headers, header)
          end
        else
          for col in header_line:gmatch('%S+') do
            table.insert(headers, col)
          end
        end

        return {
          lines = lines,
          headers = headers,
          col_ranges = col_ranges,
          header_line = header_line,
          header_idx = header_idx,
          separator_line = separator_line,
        }
      end

      -- Helper: get values for current row
      local function get_row_values(parsed)
        local lines = parsed.lines
        local col_ranges = parsed.col_ranges
        local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1]
        local cur_line = lines[cur_line_nr]

        if not cur_line or cur_line:match('^%s*%-+') or cur_line == parsed.header_line then
          return nil
        end

        -- Find row start
        local row_start = cur_line_nr
        if #col_ranges > 0 then
          local first_col_end = col_ranges[1][2]
          while row_start > 1 do
            local prev = lines[row_start - 1]
            if not prev or prev:match('^%s*%-+') or prev == parsed.header_line then break end
            local first_val = prev:sub(1, first_col_end):match('^%s*(.-)%s*$')
            if first_val and first_val ~= '' then break end
            row_start = row_start - 1
          end
        end

        -- Collect continuation lines
        local row_lines = { lines[row_start] }
        if #col_ranges > 0 then
          local first_col_end = col_ranges[1][2]
          local next_nr = row_start + 1
          while next_nr <= #lines do
            local next_line = lines[next_nr]
            if not next_line or next_line:match('^%s*%-+') or next_line == '' then break end
            local first_val = next_line:sub(1, first_col_end):match('^%s*(.-)%s*$')
            if first_val and first_val ~= '' then break end
            table.insert(row_lines, next_line)
            next_nr = next_nr + 1
          end
        end

        -- Parse values
        local values = {}
        if #col_ranges > 0 then
          for col_idx, range in ipairs(col_ranges) do
            local parts = {}
            local is_last = col_idx == #col_ranges
            for _, row_line in ipairs(row_lines) do
              local val = is_last
                and row_line:sub(range[1]):match('^%s*(.-)%s*$')
                or row_line:sub(range[1], range[2]):match('^%s*(.-)%s*$')
              if val and val ~= '' then table.insert(parts, val) end
            end
            table.insert(values, table.concat(parts, '') or 'NULL')
          end
        else
          for val in cur_line:gmatch('%S+') do
            table.insert(values, val)
          end
        end

        return values
      end

      -- Helper: format JSON
      local function format_json(str)
        local ok, decoded = pcall(vim.json.decode, str)
        if not ok then return nil end
        local ok2, encoded = pcall(vim.json.encode, decoded)
        if not ok2 then return nil end

        local indent = 0
        local result = {}
        local in_string = false
        for i = 1, #encoded do
          local char = encoded:sub(i, i)
          if char == '"' and encoded:sub(i - 1, i - 1) ~= '\\' then
            in_string = not in_string
            table.insert(result, char)
          elseif not in_string then
            if char == '{' or char == '[' then
              indent = indent + 2
              table.insert(result, char .. '\n' .. string.rep(' ', indent))
            elseif char == '}' or char == ']' then
              indent = indent - 2
              table.insert(result, '\n' .. string.rep(' ', indent) .. char)
            elseif char == ',' then
              table.insert(result, char .. '\n' .. string.rep(' ', indent))
            elseif char == ':' then
              table.insert(result, ': ')
            elseif char ~= ' ' then
              table.insert(result, char)
            end
          else
            table.insert(result, char)
          end
        end
        return table.concat(result)
      end

      -- Helper: check if looks like truncated JSON
      local function is_truncated_json(str)
        if not str then return false end
        local trimmed = str:match('^%s*(.-)%s*$')
        if not trimmed:match('^[{%[]') then return false end
        local ok = pcall(vim.json.decode, trimmed)
        return not ok
      end

      -- Helper: show popup (with optional context for fetching JSON)
      local function show_popup(content_lines, filetype, context)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines)
        if filetype then
          vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
        end

        local max_len = 0
        for _, line in ipairs(content_lines) do
          max_len = math.max(max_len, #line)
        end

        local width = math.min(120, math.max(40, max_len + 4))
        local height = math.min(#content_lines, 40)

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

        -- If context provided, add keybinding to fetch JSON for column on current line
        if context and context.original_query and context.db_info then
          vim.keymap.set('n', '<leader>dj', function()
            -- Get column name from current line
            local line = vim.api.nvim_get_current_line()
            local col_name = line:match('^(%S+)%s*:')
            if not col_name then
              vim.notify('Position cursor on a column line', vim.log.levels.WARN)
              return
            end

            -- Build query using original query as CTE, filtering by first column (ID)
            local id_col = context.headers[1]
            local id_val = context.values[1]
            local wrapped_query = string.format(
              "WITH original_result AS (%s) SELECT %s FROM original_result WHERE %s = '%s'",
              context.original_query:gsub("'", "''"),
              col_name,
              id_col,
              id_val:gsub("'", "''")
            )

            vim.notify(string.format('Fetching %s where %s = %s...', col_name, id_col, id_val), vim.log.levels.INFO)

            -- Get connection details from dadbod
            local db_url = context.db_info.db_url or context.db_info
            local parsed = vim.fn['db#url#parse'](db_url)

            -- Build sqlcmd command with -y 0 (unlimited width, no headers)
            local server = parsed.host or 'localhost'
            if parsed.port then
              server = server .. ',' .. parsed.port
            end

            -- Write query to temp file
            local tmp = vim.fn.tempname() .. '.sql'
            vim.fn.writefile({ wrapped_query }, tmp)

            -- Build command args
            local cmd_parts = { 'sqlcmd', '-S', server }

            -- Add trust certificate if specified in URL
            if parsed.params and (parsed.params.trustServerCertificate or parsed.params.TrustServerCertificate) then
              table.insert(cmd_parts, '-C')
            end

            -- Add auth
            if parsed.user then
              table.insert(cmd_parts, '-U')
              table.insert(cmd_parts, parsed.user)
              if parsed.password then
                table.insert(cmd_parts, '-P')
                table.insert(cmd_parts, parsed.password)
              end
            else
              table.insert(cmd_parts, '-E') -- Integrated auth
            end

            -- Add database
            if parsed.path and parsed.path ~= '' then
              table.insert(cmd_parts, '-d')
              local db_name = parsed.path:gsub('^/', '')
              table.insert(cmd_parts, db_name)
            end

            -- Add input file and unlimited width (no -h flag, incompatible with -y 0)
            table.insert(cmd_parts, '-i')
            table.insert(cmd_parts, tmp)
            table.insert(cmd_parts, '-y')
            table.insert(cmd_parts, '0')

            local result = vim.fn.system(cmd_parts)
            vim.fn.delete(tmp)

            if result and result ~= '' and not result:match('Sqlcmd: Error') then
              -- Clean up result: skip header line, separator line, remove "(X rows affected)"
              local json_value = result
                :gsub('^%s*' .. col_name .. '%s*\n', '')  -- Remove header line
                :gsub('^%-+%s*\n', '')                     -- Remove separator line
                :gsub('%(%d+ rows? affected%)', '')        -- Remove rows affected
                :match('^%s*(.-)%s*$')                     -- Trim

              if json_value and json_value ~= '' and json_value ~= 'NULL' then
                vim.cmd('close')

                local json_buf = vim.api.nvim_create_buf(false, true)
                local formatted = format_json(json_value)
                local content = formatted or json_value

                local lines = {}
                for l in content:gmatch('[^\n]+') do
                  table.insert(lines, l)
                end

                vim.api.nvim_buf_set_lines(json_buf, 0, -1, false, lines)
                vim.api.nvim_set_option_value('filetype', 'json', { buf = json_buf })
                vim.api.nvim_set_option_value('buftype', 'nofile', { buf = json_buf })

                vim.cmd('botright vsplit')
                vim.api.nvim_win_set_buf(0, json_buf)
                vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = json_buf })
              else
                vim.notify('No result or NULL value', vim.log.levels.WARN)
              end
            else
              vim.notify('Query failed: ' .. (result or 'unknown error'), vim.log.levels.ERROR)
            end
          end, { buffer = buf, desc = 'Fetch full JSON for this column' })
        end
      end

      -- <leader>dv: Show current row vertically
      vim.keymap.set('n', '<leader>dv', function()
        local parsed = parse_result_buffer()
        if not parsed then return end

        local values = get_row_values(parsed)
        if not values then
          vim.notify('Move cursor to a data row', vim.log.levels.WARN)
          return
        end

        -- Get original query info from b:db
        local db_info = vim.b.db
        local original_query = nil
        if db_info and db_info.input then
          local query_lines = vim.fn.readfile(db_info.input)
          original_query = table.concat(query_lines, '\n')
        end

        -- Build context for JSON fetching
        local context = {
          db_info = db_info,
          original_query = original_query,
          headers = parsed.headers,
          values = values,
        }

        local display = {}
        local max_header_len = 0
        for _, h in ipairs(parsed.headers) do
          max_header_len = math.max(max_header_len, #h)
        end

        local has_truncated = false
        for i, header in ipairs(parsed.headers) do
          local val = values[i] or 'NULL'
          local trimmed = val:match('^%s*(.-)%s*$')

          -- Check if truncated JSON
          if is_truncated_json(trimmed) then
            has_truncated = true
            table.insert(display, string.format('%-' .. max_header_len .. 's : %s [TRUNCATED]', header, trimmed:sub(1, 50) .. '...'))
          else
            table.insert(display, string.format('%-' .. max_header_len .. 's : %s', header, val))
          end
        end

        if has_truncated then
          table.insert(display, '')
          table.insert(display, '-- Position on column line and press <leader>dj to fetch full JSON')
        end

        show_popup(display, nil, context)
      end, { desc = 'Show DB row vertically' })

      -- <leader>dj: Fetch full JSON for column under cursor
      vim.keymap.set('n', '<leader>dj', function()
        local parsed = parse_result_buffer()
        if not parsed then return end

        local values = get_row_values(parsed)
        if not values then
          vim.notify('Move cursor to a data row', vim.log.levels.WARN)
          return
        end

        -- Find which column cursor is on
        local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
        local col_idx = #parsed.col_ranges -- default to last
        for i, range in ipairs(parsed.col_ranges) do
          if cursor_col >= range[1] and cursor_col <= range[2] then
            col_idx = i
            break
          elseif cursor_col < range[1] then
            col_idx = math.max(1, i - 1)
            break
          end
        end

        local column_name = parsed.headers[col_idx]
        local id_value = values[1] -- Assume first column is ID

        if not column_name or not id_value then
          vim.notify('Could not determine column or ID', vim.log.levels.ERROR)
          return
        end

        -- Try to get table name from buffer name
        local buf_name = vim.api.nvim_buf_get_name(0)
        local table_name = buf_name:match('([%w_]+)%.dbout$') or buf_name:match('([%w_]+)$')

        if not table_name or table_name == '' then
          vim.ui.input({ prompt = 'Table name: ' }, function(input)
            if input and input ~= '' then
              table_name = input
            else
              return
            end
          end)
        end

        -- Get first column name for WHERE clause
        local id_column = parsed.headers[1]

        vim.notify(string.format('Fetching %s.%s where %s = %s...', table_name, column_name, id_column, id_value), vim.log.levels.INFO)

        -- Run query using vim-dadbod
        local query = string.format("SELECT %s FROM %s WHERE %s = '%s'", column_name, table_name, id_column, id_value)
        local result = vim.fn['db#execute'](db_url, query)

        if result and result ~= '' then
          -- Parse result - skip header and separator
          local result_lines = vim.split(result, '\n')
          local json_value = ''
          local data_started = false
          for _, line in ipairs(result_lines) do
            if line:match('^%s*%-+') then
              data_started = true
            elseif data_started and line:match('%S') then
              json_value = json_value .. line:match('^%s*(.-)%s*$')
            end
          end

          if json_value ~= '' then
            local formatted = format_json(json_value)
            if formatted then
              local display = {}
              table.insert(display, '-- ' .. column_name)
              table.insert(display, '')
              for json_line in formatted:gmatch('[^\n]+') do
                table.insert(display, json_line)
              end
              show_popup(display, 'json')
            else
              vim.notify('Could not parse JSON: ' .. json_value:sub(1, 100), vim.log.levels.ERROR)
            end
          else
            vim.notify('No result returned', vim.log.levels.WARN)
          end
        else
          vim.notify('Query failed', vim.log.levels.ERROR)
        end
      end, { desc = 'Fetch full JSON for column' })
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
