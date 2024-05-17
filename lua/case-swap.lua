---@class Config
local config = {
  opt = {},
}

---@class Irc
local M = {}

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.replace_word_under_cursor = function(new_word)
  local current_line = vim.fn.getline(".")
  local cursor_pos = vim.fn.col(".")
  local current_line_number = vim.fn.line(".")
  local start_pos, end_pos = cursor_pos, cursor_pos

  -- Find the start of the word
  while start_pos > 1 and string.match(current_line:sub(start_pos - 1, start_pos - 1), "[%w_]") do
    start_pos = start_pos - 1
  end

  -- Find the end of the word
  while end_pos <= string.len(current_line) and string.match(current_line:sub(end_pos, end_pos), "[%w_]") do
    end_pos = end_pos + 1
  end

  local replaced_word = current_line:sub(start_pos, end_pos - 1)
  local new_line = current_line:sub(1, start_pos - 1) .. new_word .. current_line:sub(end_pos)
  vim.fn.setline(current_line_number, new_line)
  vim.fn.cursor({ current_line_number, start_pos + string.len(new_word) })
  return replaced_word
end

M.case_camel_to_snake_case = function()
  local word = vim.fn.expand("<cword>")
  local new_word = word:gsub("%u", function(c)
    return "_" .. c:lower()
  end)
  M.replace_word_under_cursor(new_word)
end

M.case_snake_to_camel = function()
  local word = vim.fn.expand("<cword>")
  local new_word = word:gsub("_(%a)", function(c)
    return c:upper()
  end)
  M.replace_word_under_cursor(new_word)
end

return M
