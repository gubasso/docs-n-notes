# Lang: Rust

## Rust + Vimux

At `"$NVIM_CONFIG_DIR"/lua/lang/rust.lua`:

```lua
local au = require('core.autocmds')
local k = require("which-key").register

vim.api.nvim_create_autocmd("FileType", {
  group = au.augroup("rustlang"),
  pattern = { "rust" },
  callback = function()
    k(
      {
        prefix = "<LocalLeader>",
        name = "Rust",
        x = { '<cmd>wa<CR><cmd>call VimuxRunCommand("cl; cargo fix --allow-staged")<cr>', '(vmux) cargo fix --allow-staged' },
        f = { '<cmd>wa<CR><cmd>call VimuxRunCommand("cl; cargo fmt --check; cargo fmt")<cr>', '(vmux) cargo fmt check & run' },
      },
      {
        buffer = 0
      }
    )
    local buf = vim.api.nvim_get_current_buf()
    k(
    'n',
    '<LocalLeader>f',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("cl; cargo fix --allow-staged")<cr>',
    {
      desc = '(vmux) cargo fix --allow-staged',
      buffer = buf,
    })
    vim.keymap.set(
    'n',
    '<LocalLeader>T',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo nextest run")<cr>',
    {
      desc = '(vmux) Rust Run All Tests',
      buffer = buf,
    })
    vim.keymap.set(
    'n',
    '<LocalLeader>t',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo nextest run -p " . expand("%:.:h:h") . " --no-capture --test-threads 1")<cr>',
    {
      desc = '(vmux) Rust Run Test (file)',
      buffer = buf,
    })
    vim.keymap.set(
    'n',
    '<LocalLeader>c',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo clippy --package " . expand("%:.:h:h"))<cr>',
    {
      desc = '(vmux) Rust Cargo Clippy',
      buffer = buf,
    })
    vim.keymap.set(
    'n',
    '<LocalLeader>f',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo fmt --check")<cr>',
    {
      desc = '(vmux) Rustfm (check)',
      buffer = buf,
    })
    vim.keymap.set(
    'n',
    '<LocalLeader>F',
    '<cmd>wa<CR><cmd>call VimuxRunCommand("clrm; cargo fmt")<cr>',
    {
      desc = '(vmux) Rustfm (check)',
      buffer = buf,
    })
  end,
})
```
