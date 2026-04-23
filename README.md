# Case Swap

### **SETUP**

**Lazy**
```lua
{
  'cowboy8625/case-swap.nvim'
  config = function()
  -- Default Options
  require('case-swap').setup({
    default_keymaps = true
  })
  end
},

```

**Native**
For version 0.12 you can use the native package manager see :help vim.pack
```lua
vim.pack.add({ 'https://github.com/cowboy8625/case-swap.nvim' })
-- Default Options
require('case-swap').setup({
  default_keymaps = true
})
```

**Default Keymaps**

<leader>css                        any word to snake_case
<leader>csc                        any word to camelCase
<leader>cst                        any word to TitleCase
<leader>csk                        any word to kebab-case

### **Commands**

**:CaseSwap** {args}           Run CaseSwap command {args} can be any of the cases
                               as an {args} 'title' | 'snake' |  'camel' | 'kebab'

