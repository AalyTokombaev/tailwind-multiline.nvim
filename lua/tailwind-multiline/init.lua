-- tailwind-multiline.nvim
-- Transform inline Tailwind className strings into multi-line template literals

local M = {}

M.config = {
  keymaps = {
    expand = "<leader>xs",   -- Set to false to disable
    collapse = "<leader>xS", -- Set to false to disable
  },
  auto_indent = true, -- Enable smart indentation for o, O, and Enter
}

local function transform_classname()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  -- Match className="..." or className='...'
  local pattern_double = 'className="([^"]*)"'
  local pattern_single = "className='([^']*)'"

  local classes, quote_char
  classes = line:match(pattern_double)
  if classes then
    quote_char = '"'
  else
    classes = line:match(pattern_single)
    quote_char = "'"
  end

  if not classes then
    vim.notify("No className found on current line", vim.log.levels.WARN)
    return
  end

  -- Split classes by whitespace
  local class_list = {}
  for class in classes:gmatch("%S+") do
    table.insert(class_list, class)
  end

  if #class_list == 0 then
    vim.notify("No classes found in className", vim.log.levels.WARN)
    return
  end

  -- Get the indentation of the current line
  local indent = line:match("^(%s*)")
  local attr_indent = indent .. "  " -- Extra indent for the template literal content

  -- Build the replacement
  local before_classname = line:match("^(.-)className=")
  local after_classname = line:match('className=' .. quote_char .. '[^' .. quote_char .. ']*' .. quote_char .. '(.*)')

  -- Build multi-line version
  local new_lines = {}
  table.insert(new_lines, before_classname .. "className={")
  table.insert(new_lines, attr_indent .. "`" .. class_list[1])
  for i = 2, #class_list do
    table.insert(new_lines, attr_indent .. class_list[i])
  end
  -- Close the template literal and add anything after
  new_lines[#new_lines] = new_lines[#new_lines] .. "\n" .. attr_indent .. "`"
  table.insert(new_lines, indent .. "}" .. (after_classname or ""))

  -- Flatten the lines (handle the embedded newline)
  local final_lines = {}
  for _, l in ipairs(new_lines) do
    for part in l:gmatch("[^\n]+") do
      table.insert(final_lines, part)
    end
  end

  -- Replace the line with new lines
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, final_lines)

  vim.notify("Transformed className to multi-line format", vim.log.levels.INFO)
end

local function collapse_classname()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Find the start of className={
  local start_line = line_num
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Search backwards to find className={
  while start_line >= 1 do
    if lines[start_line]:match("className={") then
      break
    end
    start_line = start_line - 1
  end

  if start_line < 1 or not lines[start_line]:match("className={") then
    vim.notify("No className={ found", vim.log.levels.WARN)
    return
  end

  -- Find the closing }
  local end_line = start_line
  local brace_count = 0
  local found_closing = false

  for i = start_line, total_lines do
    local line = lines[i]
    for char in line:gmatch(".") do
      if char == "{" then
        brace_count = brace_count + 1
      elseif char == "}" then
        brace_count = brace_count - 1
        if brace_count == 0 then
          end_line = i
          found_closing = true
          break
        end
      end
    end
    if found_closing then break end
  end

  if not found_closing then
    vim.notify("Could not find closing brace", vim.log.levels.WARN)
    return
  end

  -- Extract all classes from the multi-line format
  local all_classes = {}
  for i = start_line, end_line do
    local line = lines[i]
    -- Remove className={, backticks, and closing }
    local cleaned = line:gsub("className={", ""):gsub("`", ""):gsub("}", "")
    for class in cleaned:gmatch("%S+") do
      table.insert(all_classes, class)
    end
  end

  -- Build the inline version
  local before = lines[start_line]:match("^(.-)className=")
  local after = lines[end_line]:match("}(.*)$") or ""
  local inline = before .. 'className="' .. table.concat(all_classes, " ") .. '"' .. after

  -- Replace the lines
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, { inline })

  vim.notify("Collapsed className to inline format", vim.log.levels.INFO)
end

-- Helper function to check if we're inside a className template literal
local function get_classname_block_indent()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local current_line = lines[line_num]

  -- Search backwards for className={
  for i = line_num, math.max(1, line_num - 20), -1 do
    if lines[i]:match("className={") then
      -- Found opening, now check if there's a closing backtick after current line
      for j = i, math.min(#lines, line_num + 20) do
        if lines[j]:match("`%s*$") and j > line_num then
          -- We're inside the block
          return current_line:match("^(%s*)")
        end
        if lines[j]:match("}%s*>?%s*$") and j <= line_num then
          -- Block already closed before our line
          return nil
        end
      end
      break
    end
  end
  return nil
end

local function setup_auto_indent()
  -- Auto-indent when pressing 'o' inside a className template literal
  vim.keymap.set("n", "o", function()
    local block_indent = get_classname_block_indent()

    if block_indent then
      -- Open new line with matching indentation
      vim.cmd("normal! o")
      local new_line_num = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(0, new_line_num - 1, new_line_num, false, { block_indent })
      vim.api.nvim_win_set_cursor(0, { new_line_num, #block_indent })
      vim.cmd("startinsert!")
    else
      -- Default 'o' behavior
      vim.cmd("normal! o")
      vim.cmd("startinsert!")
    end
  end, { desc = "Smart newline with className indent" })

  -- Auto-indent when pressing 'O' inside a className template literal
  vim.keymap.set("n", "O", function()
    local block_indent = get_classname_block_indent()

    if block_indent then
      -- Open new line above with matching indentation
      vim.cmd("normal! O")
      local new_line_num = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(0, new_line_num - 1, new_line_num, false, { block_indent })
      vim.api.nvim_win_set_cursor(0, { new_line_num, #block_indent })
      vim.cmd("startinsert!")
    else
      -- Default 'O' behavior
      vim.cmd("normal! O")
      vim.cmd("startinsert!")
    end
  end, { desc = "Smart newline above with className indent" })

  -- Auto-indent when pressing Enter in insert mode inside a className template literal
  vim.keymap.set("i", "<CR>", function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local current_line = lines[line_num]
    local block_indent = nil

    -- Search backwards for className={
    for i = line_num, math.max(1, line_num - 20), -1 do
      if lines[i]:match("className={") then
        -- Found opening, now check if there's a closing backtick after current line
        for j = i, math.min(#lines, line_num + 20) do
          if lines[j]:match("`%s*$") and j >= line_num then
            -- We're inside the block
            block_indent = current_line:match("^(%s*)")
            break
          end
          if lines[j]:match("}%s*>?%s*$") and j < line_num then
            -- Block already closed before our line
            break
          end
        end
        break
      end
    end

    if block_indent then
      -- Insert newline and matching indentation
      local key = vim.api.nvim_replace_termcodes("<CR>" .. block_indent, true, false, true)
      vim.api.nvim_feedkeys(key, "n", false)
    else
      -- Default Enter behavior
      local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      vim.api.nvim_feedkeys(key, "n", false)
    end
  end, { desc = "Smart Enter with className indent" })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create commands
  vim.api.nvim_create_user_command("TailwindMultiline", transform_classname, {
    desc = "Transform inline className to multi-line template literal",
  })

  vim.api.nvim_create_user_command("TailwindInline", collapse_classname, {
    desc = "Collapse multi-line className to inline",
  })

  -- Create keymaps
  if M.config.keymaps.expand then
    vim.keymap.set("n", M.config.keymaps.expand, transform_classname, {
      desc = "Tailwind: Expand className to multi-line",
    })
  end

  if M.config.keymaps.collapse then
    vim.keymap.set("n", M.config.keymaps.collapse, collapse_classname, {
      desc = "Tailwind: Collapse className to inline",
    })
  end

  -- Setup auto-indent if enabled
  if M.config.auto_indent then
    setup_auto_indent()
  end
end

-- Expose functions for manual use
M.expand = transform_classname
M.collapse = collapse_classname

return M
