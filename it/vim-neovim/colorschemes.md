# Vim/Neovim: Colorschemes

Using lazy.nvim as plugin manager:

```lua
return {
  {
      "chrsm/paramount-ng.nvim",
      dependencies = {
        "rktjmp/lush.nvim"
      },
      lazy = false,
      priority = 1000,
      init = function()
          vim.cmd.colorscheme("paramount-ng")
      end,
  },
}
```


