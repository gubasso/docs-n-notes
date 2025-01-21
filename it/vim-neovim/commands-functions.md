# Commands cmds functions


```lua
-- Function for highlighting the visual selection upon pressing <CR> in Visual mode
local highlight_selection = function()
  -- Yank selection into the * register
  vim.cmd.normal({ '"*y', bang = true })

  -- Read from the * register
  local text = vim.fn.getreg("*")

  -- Escape special characters (\/) and replace newlines
  text = vim.fn.escape(text, "\\/")
  text = vim.fn.substitute(text, "\n", "\\n", "g")

  -- Prepend '\V' for "very nomagic" to match literally
  local searchTerm = "\\V" .. text

  -- Set Vim's search register, print it, add to history, and enable hlsearch
  vim.fn.setreg("/", searchTerm)
  print("/" .. searchTerm)
  vim.fn.histadd("search", searchTerm)
  vim.opt.hlsearch = true
end

-- Function for highlighting the word under cursor on <leader><CR> in Normal mode
local highlight_cword = function()
  -- Expand the <cword>, and wrap it with \v<...> for "very magic" mode
  local cword = vim.fn.expand("<cword>")
  local searchTerm = "\\v<" .. cword .. ">"

  -- Set Vim's search register, print it, add to history, and enable hlsearch
  vim.fn.setreg("/", searchTerm)
  print("/" .. searchTerm)
  vim.fn.histadd("search", searchTerm)
  vim.opt.hlsearch = true
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      { "<CR>", highlight_selection, desc = "Highlighting visual selection", mode = "v" },
      { "<leader><CR>", highlight_cword, desc = "Highlighting word under cursor" },
    },
```

above is the same as:

```lua
vim.cmd([[
" [Automatically highlight all occurrences of the selected text in visual mode](https://vi.stackexchange.com/questions/20077/automatically-highlight-all-occurrences-of-the-selected-text-in-visual-mode)
" highlight the visual selection after pressing enter.
xnoremap <silent> <cr> "*y:silent! let searchTerm = '\V'.substitute(escape(@*, '\/'), "\n", '\\n', "g") <bar> let @/ = searchTerm <bar> echo '/'.@/ <bar> call histadd("search", searchTerm) <bar> set hls<cr>
" Put <enter> to work too! Otherwise <enter> moves to the next line, which we can
" already do by pressing the <j> key, which is a waste of keys!
" Be useful <enter> key!:
nnoremap <silent> <leader><cr> :let searchTerm = '\v<'.expand("<cword>").'>' <bar> let @/ = searchTerm <bar> echo '/'.@/ <bar> call histadd("search", searchTerm) <bar> set hls<cr>
]])
```
