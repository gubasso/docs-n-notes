# Plugin: Tmux / Vimux

```lua
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    config = function ()
      vim.g.tmux_navigator_disable_when_zoomed = 1
      vim.g.tmux_navigator_preserve_zoom = 1
    end
  },
  {
    'preservim/vimux',
    lazy = false,
    config = function ()
      vim.cmd([[
          let g:VimuxHeight = "45"
          let g:VimuxOrientation = "h"
          ]])
      require("which-key").register({
        prefix = "<leader>v",
        name = 'vimux',
        o = { '<cmd>VimuxOpenRunner<cr>', 'Vimux Open Runner' },
        c = { '<cmd>VimuxPromptCommand<cr>', 'Vimux Prompt Command' },
        l = { '<cmd>VimuxRunLastCommand<cr>', 'Vimux Run Last Command' },
        i = { '<cmd>VimuxInspectRunner<cr>', 'Vimux Inspect Runner' },
        q = { '<cmd>VimuxCloseRunner<cr>', 'Vimux Close Runner' },
      })
    end
  },
```
