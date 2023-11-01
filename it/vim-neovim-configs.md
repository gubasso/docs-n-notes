# Vim / Neovim configurations configs
> nvim

<!-- toc GFM -->

+ [lazy.nvim](#lazynvim)
  * [Load for filetype](#load-for-filetype)
    - [1. ftplugin dir: `after/ftplugin/<filetype>.lua`](#1-ftplugin-dir-afterftpluginfiletypelua)
    - [2. lazy.nvim pure](#2-lazynvim-pure)
+ [Plugins](#plugins)
  * [which-key](#which-key)
+ [nvim lua commands](#nvim-lua-commands)
  * [table/list manipulation](#tablelist-manipulation)

<!-- toc -->

# lazy.nvim


## Load for filetype

### 1. ftplugin dir: `after/ftplugin/<filetype>.lua`

With this method, can't call lazy.nvim plugins from inside (e.g. `require("which-key")`)

- https://neovim.io/doc/user/usr_43.html#filetype-plugin
- https://neovim.io/doc/user/usr_05.html#add-filetype-plugin

e.g. load within `after/ftplugin/rust.lua`

```lua
vim.keymap.set(
  'n',
  '<LocalLeader>t',
  '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo test -p " . expand("%:.:h:h") . " -- --nocapture --test-threads 1")<cr>',
  { desc = 'Run Test this file' })
```


### 2. lazy.nvim pure

can call plugins

at `init.lua`

```lua
-- after load plugins
-- e.g. require"lazy".setup('plugins')
require"lazy".setup('plugins')

-- load lua file
-- loads `lua/lang/init.lua`
require('lang')
-- loads `lua/lang/rust.lua`
require('lang.rust')
```

at `lua/lang/markdown.lua`

```lua
- e.g. for requiring plugin
local wk = require('which-key')

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    -- vim.opt_local.spell = true
  end,
})

-- close some filetypes with <q>
-- to be applied specific buffers
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "man",
  },
  callback = function(event)
    -- local buf = vim.api.nvim_get_current_buf()
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
```

# Plugins

## which-key

**compose configurations multiple places**

```lua
  {
    "folke/which-key.nvim",
    optional = true,
    -- compose here
    opts = {
      defaults = {
        ["<leader>t"] = { name = "+test" },
      },
    },
  },
```

# nvim lua commands

## table/list manipulation

https://neovim.io/doc/user/lua.html#vim.tbl_extend()

https://neovim.io/doc/user/lua.html#vim.list_extend()
```lua
  {
    "williamboman/mason.nvim",
    ft = 'rust',
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "codelldb" })
      end
    end,
  },
```


```lua
ft = 'rust',
event = {"BufReadPre *.rs" },
opts = function(_, opts)
  opts.ensure_installed = vim.list_extend(opts.ensure_installed, { "ron", "rust", "toml" })
end,
opts = function(_, opts)
  if type(opts.ensure_installed) == "table" then
    vim.list_extend(opts.ensure_installed, {
      "codelldb",
      "rust-analyzer",
      "rustfmt",
    })
  end
end,
```
