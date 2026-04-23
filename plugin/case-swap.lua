local case_swap = require("case-swap")

local M = {}

local name_to_kind = {
    title = case_swap.CaseKind.title,
    snake = case_swap.CaseKind.snake,
    camel = case_swap.CaseKind.camel,
    kebab = case_swap.CaseKind.kebab,
}

local kind_names = { "title", "snake", "camel", "kebab" }

local function get_word_under_cursor()
    local win = vim.api.nvim_get_current_win()
    local row, col = unpack(vim.api.nvim_win_get_cursor(win))
    local line = vim.api.nvim_get_current_line()
    if line == "" then
        return ""
    end
    local s = col
    local e = col + 1
    while s > 0 and line:sub(s, s):match("[%w%-%_]") do
        s = s - 1
    end
    while e <= #line and line:sub(e, e):match("[%w%-%_]") do
        e = e + 1
    end
    local word = line:sub(s + 1, e - 1)
    return word, row, s + 1, e - 1
end

local function apply_replacement(range_row, start_col, end_col, replacement)
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_buf_get_lines(bufnr, range_row - 1, range_row, true)[1]
    local new_line = line:sub(1, start_col - 1) .. replacement .. line:sub(end_col + 1)
    vim.api.nvim_buf_set_lines(bufnr, range_row - 1, range_row, true, { new_line })
end

local function pick_target_with_telescope(on_choice)
    local ok, pickers = pcall(require, "telescope.pickers")
    if ok then
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers
            .new({}, {
                prompt_title = "CaseSwap: target",
                finder = finders.new_table({ results = kind_names }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        on_choice(selection[1])
                    end)
                    return true
                end,
            })
            :find()
    else
        -- fallback to vim.ui.select
        vim.ui.select(kind_names, { prompt = "CaseSwap target:" }, function(choice)
            if choice then
                on_choice(choice)
            end
        end)
    end
end

local function parse_arg(arg)
    if not arg or arg == "" then
        return nil
    end
    arg = vim.trim(arg):lower()
    return name_to_kind[arg]
end

--- Public command function: argstring is the raw argument passed by the command
---@param argstring string
M.case_swap_cmd = function(argstring)
    local target = parse_arg(argstring)
    local word, row, s_col, e_col = get_word_under_cursor()
    if not word or word == "" then
        vim.notify("CaseSwap: no word under cursor", vim.log.levels.WARN)
        return
    end

    local function do_swap(kind_name)
        local kind = name_to_kind[kind_name]
        if not kind then
            vim.notify(("CaseSwap: unknown target %s"):format(tostring(kind_name)), vim.log.levels.ERROR)
            return
        end
        local replaced = case_swap.convert(word, kind)
        apply_replacement(row, s_col, e_col, replaced)
    end

    if target then
        for name, k in pairs(name_to_kind) do
            if k == target then
                do_swap(name)
                return
            end
        end
        vim.notify("CaseSwap: invalid target", vim.log.levels.ERROR)
        return
    end

    pick_target_with_telescope(function(choice)
        if choice then
            do_swap(choice)
        end
    end)
end

vim.api.nvim_create_user_command("CaseSwap", function(opts)
    M.case_swap_cmd(opts.args)
end, {
    nargs = "?",
    complete = function(ArgLead)
        local res = {}
        for _, name in ipairs(kind_names) do
            if name:match("^" .. vim.pesc(ArgLead)) then
                res[#res + 1] = name
            end
        end
        return res
    end,
})

if case_swap.config.default_keybindings then
    vim.keymap.set("n", "<leader>css", function()
        M.case_swap_cmd("snake")
    end, { desc = "[C]ase [S]wap [S]nake", silent = true })
    vim.keymap.set("n", "<leader>csc", function()
        M.case_swap_cmd("camel")
    end, { desc = "[C]ase [S]wap [C]amel", silent = true })
    vim.keymap.set("n", "<leader>cst", function()
        M.case_swap_cmd("title")
    end, { desc = "[C]ase [S]wap [T]itle", silent = true })
    vim.keymap.set("n", "<leader>csk", function()
        M.case_swap_cmd("kebab")
    end, { desc = "[C]ase [S]wap [K]ebab", silent = true })
end

return M
