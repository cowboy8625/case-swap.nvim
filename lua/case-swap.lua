---@class Config
local config = {
  opt = {},
}

---@class CaseSwap
local M = {}

---@enum CaseKind
M.CaseKind = {
  title = 1,
  snake = 2,
  camel = 3,
  kebab = 4,
}

M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or config)
end

local function is_title(word)
  -- Title case: single token where each word-start is uppercase (PascalCase / TitleCase),
  -- e.g. "Hello" or "HelloWorld". No spaces or separators allowed.
  if word:find("%s") then
    return false
  end
  -- must start with uppercase and contain no separators; allow digits inside
  return word:match("^%u[%w]*$") ~= nil and word:match("%u") ~= nil
end

local function is_snake(word)
  -- snake_case: only lowercase letters, digits and underscores, at least one underscore or all lowercase single token
  return word:match("^[a-z0-9_]+$") ~= nil and word:match("_") ~= nil
end

local function is_kebab(word)
  -- kebab-case: only lowercase letters, digits and hyphens, at least one hyphen
  return word:match("^[a-z0-9%-]+$") ~= nil and word:match("%-") ~= nil
end

local function is_camel(word)
  -- camelCase or PascalCase: contains uppercase letters without separators
  -- treat both lowerCamel and UpperCamel as camel here
  if word:find("[%_%-%s]") then
    return false
  end
  -- must contain at least one uppercase letter and at least one lowercase letter
  return word:match("%u") and word:match("%l")
end

---@param word string
---@return CaseKind?
M.detect_case_kind = function(word)
  if not word or word == "" then
    return nil
  end
  if is_title(word) then
    return M.CaseKind.title
  end
  if is_snake(word) then
    return M.CaseKind.snake
  end
  if is_kebab(word) then
    return M.CaseKind.kebab
  end
  if is_camel(word) then
    return M.CaseKind.camel
  end
  -- fallback: if all-lower single token treat as snake, else camel
  if word:match("^[a-z0-9]+$") then
    return M.CaseKind.snake
  end
  return M.CaseKind.camel
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

---@param word string
---@return string[]
local function split_to_words(word)
  -- Normalize separators to spaces, then split camel/Pascal into words.
  if not word or word == "" then
    return {}
  end

  -- Replace underscores and hyphens with spaces
  local s = word:gsub("[%_%-]", " ")

  -- Insert space between lowercase->Uppercase transitions and between digit->alpha and alpha->digit
  s = s:gsub("(%l)(%u)", "%1 %2")
  s = s:gsub("(%d)(%a)", "%1 %2")

  local words = {}
  for w in s:gmatch("%S+") do
    -- Split runs of uppercase letters that are followed by lowercase (e.g., "HTMLParser" -> "HTML Parser")
    local i = 1
    while i <= #w do
      local rest = w:sub(i)
      local a, b = rest:match("^([A-Z]+)([A-Z][a-z]%w*)")
      if a and b then
        table.insert(words, a)
        w = b
        i = 1
      else
        table.insert(words, rest)
        break
      end
    end
  end

  -- Further split any remaining camel inside tokens (e.g., "helloWorld")
  local final = {}
  for _, token in ipairs(words) do
    local t = token
    local buf = ""
    for i = 1, #t do
      local ch = t:sub(i, i)
      local next_ch = t:sub(i + 1, i + 1)
      buf = buf .. ch
      if next_ch:match("%u") and ch:match("%l") then
        table.insert(final, buf)
        buf = ""
      end
      if i == #t and buf ~= "" then
        table.insert(final, buf)
      end
    end
  end

  -- Normalize tokens to lowercase except keep numeric tokens as-is
  for i, v in ipairs(final) do
    if v:match("^%d+$") then
      final[i] = v
    else
      final[i] = v:lower()
    end
  end

  return final
end

---@param words string[]
---@return string
local function to_title(words)
  for i, w in ipairs(words) do
    words[i] = w:sub(1, 1):upper() .. (w:sub(2) or "")
  end
  return table.concat(words, "")
end

---@param words string[]
---@return string
local function to_snake(words)
  return table.concat(words, "_")
end

---@param words string[]
---@return string
local function to_kebab(words)
  return table.concat(words, "-")
end

---@param words string[]
---@return string
local function to_camel(words)
  if #words == 0 then
    return ""
  end
  local first = words[1]
  local rest = {}
  for i = 2, #words do
    local w = words[i]
    rest[#rest + 1] = w:sub(1, 1):upper() .. (w:sub(2) or "")
  end
  return first .. table.concat(rest, "")
end

---@param word string
---@param to CaseKind
---@return string
M.convert = function(word, to)
  local words = split_to_words(word)
  if to == M.CaseKind.title then
    return to_title(words)
  elseif to == M.CaseKind.snake then
    return to_snake(words)
  elseif to == M.CaseKind.camel then
    return to_camel(words)
  elseif to == M.CaseKind.kebab then
    return to_kebab(words)
  end
  error("unknown case kind")
end

return M
