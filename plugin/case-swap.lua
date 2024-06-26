local case_swap = require("case-swap")
vim.api.nvim_create_user_command("CaseSwapSnakeToCamelCase", case_swap.case_snake_to_camel, {})
vim.api.nvim_create_user_command("CaseSwapCamelToSnakeCase", case_swap.case_camel_to_snake, {})
vim.keymap.set("n", "swc", ":CaseSwapSnakeToCamelCase<CR>", { desc = "Swap [W]ord to [C]amel case", silent = true })
vim.keymap.set("n", "sws", ":CaseSwapCamelToSnakeCase<CR>", { desc = "Swap [W]ord to [S]nake case", silent = true })
