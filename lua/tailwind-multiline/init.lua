-- tailwind-multiline.nvim
-- Transform inline Tailwind className strings into multi-line template literals

local M = {}

M.config = {
	keymaps = {
		expand = "<leader>xs", -- Set to false to disable
		collapse = "<leader>xS", -- Set to false to disable
	},
	auto_indent = true, -- Enable smart indentation for o, O, and Enter
}

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- Parse a className attribute from a line
-- Returns: classes_string, quote_type, prefix, suffix
local function parse_inline_classname(line)
	-- Try double quotes
	local prefix = line:match('^(.-)className="')
	if prefix then
		local classes = line:match('className="([^"]*)"')
		local suffix = line:match('className="[^"]*"(.*)')
		return classes, '"', prefix, suffix
	end
	-- Try single quotes
	prefix = line:match("^(.-)className='")
	if prefix then
		local classes = line:match("className='([^']*)'")
		local suffix = line:match("className='[^']*'(.*)")
		return classes, "'", prefix, suffix
	end

	return nil
end

-- Split a space-separated string into a list
local function split_classes(class_string)
	local result = {}
	for class in class_string:gmatch("%S+") do
		table.insert(result, class)
	end
	return result
end

-- Find the line range of a className={ ... } block
-- Returns: start_line, end_line (both 1-indexed)
local function find_classname_block(lines, cursor_line)
	-- Search backwards for className={
	local start_line = nil
	for i = cursor_line, 1, -1 do
		if lines[i]:match("className%s*=%s*{") then
			start_line = i
			break
		end
	end

	if not start_line then
		return nil, nil
	end

	-- Find matching closing brace
	local brace_count = 0
	for i = start_line, #lines do
		local line = lines[i]
		for char in line:gmatch(".") do
			if char == "{" then
				brace_count = brace_count + 1
			elseif char == "}" then
				brace_count = brace_count - 1
				if brace_count == 0 then
					return start_line, i
				end
			end
		end
	end

	return nil, nil
end

-- Extract classes from a multi-line className block
local function extract_classes_from_block(lines, start_line, end_line)
	local classes = {}

	for i = start_line, end_line do
		local line = lines[i]

		-- Skip lines that are just structural (className={, }, backticks)
		if i == start_line then
			-- First line: get everything after `className={` and opening backtick
			local content = line:match("className%s*=%s*{%s*`%s*(.*)$")
			if content and content ~= "" then
				for class in content:gmatch("%S+") do
					table.insert(classes, class)
				end
			end
		elseif i == end_line then
			-- Last line: get everything before closing backtick and brace
			local content = line:match("^%s*(.-)%s*`%s*}") or line:match("^%s*(.-)%s*}")
			if content and content ~= "" then
				for class in content:gmatch("%S+") do
					table.insert(classes, class)
				end
			end
		else
			-- Middle lines: get all non-whitespace tokens that aren't backticks
			local content = line:gsub("`", "")
			for class in content:gmatch("%S+") do
				table.insert(classes, class)
			end
		end
	end

	return classes
end

-- Check if cursor is inside a className template literal block
-- Returns the indent string if inside, nil otherwise
local function get_current_block_indent(lines, cursor_line)
	local start_line, end_line = find_classname_block(lines, cursor_line)

	if not start_line or not end_line then
		return nil
	end

	-- Check if cursor is actually inside the block
	if cursor_line < start_line or cursor_line > end_line then
		return nil
	end

	-- Check if we're inside the template literal (between backticks)
	local found_opening_tick = false
	for i = start_line, cursor_line do
		if lines[i]:match("`") then
			found_opening_tick = true
			break
		end
	end

	local found_closing_tick = false
	for i = cursor_line, end_line do
		if lines[i]:match("`%s*$") or lines[i]:match("`%s*}") then
			found_closing_tick = true
			break
		end
	end

	if found_opening_tick and found_closing_tick then
		return lines[cursor_line]:match("^(%s*)")
	end

	return nil
end

--------------------------------------------------------------------------------
-- Main Functions
--------------------------------------------------------------------------------

-- Transform inline className="..." to multi-line template literal
local function transform_classname()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, cursor_line - 1, cursor_line, false)[1]

	-- Parse the className attribute
	local class_string, quote_type, prefix, suffix = parse_inline_classname(line)

	if not class_string then
		vim.notify("No className found on current line", vim.log.levels.WARN)
		return
	end

	local classes = split_classes(class_string)

	if #classes == 0 then
		vim.notify("No classes found in className", vim.log.levels.WARN)
		return
	end

	-- Build multi-line version
	local indent = line:match("^(%s*)")
	local content_indent = indent .. "  "

	local new_lines = {}
	table.insert(new_lines, prefix .. "className={")
	table.insert(new_lines, content_indent .. "`" .. classes[1])

	for i = 2, #classes do
		table.insert(new_lines, content_indent .. classes[i])
	end

	table.insert(new_lines, content_indent .. "`")
	table.insert(new_lines, indent .. "}" .. suffix)

	-- Replace the line
	vim.api.nvim_buf_set_lines(0, cursor_line - 1, cursor_line, false, new_lines)

	vim.notify("Expanded className to multi-line", vim.log.levels.INFO)
end

-- Collapse multi-line className={ ... } to inline
local function collapse_classname()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find the className block
	local start_line, end_line = find_classname_block(lines, cursor_line)

	if not start_line or not end_line then
		vim.notify("No className={ } block found", vim.log.levels.WARN)
		return
	end

	-- Extract all classes
	local classes = extract_classes_from_block(lines, start_line, end_line)

	if #classes == 0 then
		vim.notify("No classes found in block", vim.log.levels.WARN)
		return
	end

	-- Build inline version
	local prefix = lines[start_line]:match("^(.-)className%s*=%s*{")
	local suffix = lines[end_line]:match("}(.*)$") or ""
	local inline = prefix .. 'className="' .. table.concat(classes, " ") .. '"' .. suffix

	-- Replace the lines
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, { inline })

	vim.notify("Collapsed className to inline", vim.log.levels.INFO)
end

--------------------------------------------------------------------------------
-- Auto-indent Setup
--------------------------------------------------------------------------------

-- Create a new line with proper indentation
local function insert_line_with_indent(mode, direction)
	return function()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local block_indent = get_current_block_indent(lines, cursor_line)

		if block_indent then
			-- We're inside a className block - use smart indent
			if direction == "below" then
				vim.cmd("normal! o")
			else
				vim.cmd("normal! O")
			end

			local new_line_num = vim.api.nvim_win_get_cursor(0)[1]
			vim.api.nvim_buf_set_lines(0, new_line_num - 1, new_line_num, false, { block_indent })
			vim.api.nvim_win_set_cursor(0, { new_line_num, #block_indent })
			vim.cmd("startinsert!")
		else
			-- Default behavior
			if direction == "below" then
				vim.cmd("normal! o")
			else
				vim.cmd("normal! O")
			end
			vim.cmd("startinsert!")
		end
	end
end

local function setup_auto_indent()
	vim.keymap.set("n", "o", insert_line_with_indent("n", "below"), {
		desc = "Smart newline below with className indent",
	})

	vim.keymap.set("n", "O", insert_line_with_indent("n", "above"), {
		desc = "Smart newline above with className indent",
	})

	vim.keymap.set("i", "<CR>", function()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local block_indent = get_current_block_indent(lines, cursor_line)

		if block_indent then
			local key = vim.api.nvim_replace_termcodes("<CR>" .. block_indent, true, false, true)
			vim.api.nvim_feedkeys(key, "n", false)
		else
			local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
			vim.api.nvim_feedkeys(key, "n", false)
		end
	end, { desc = "Smart Enter with className indent" })
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

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
