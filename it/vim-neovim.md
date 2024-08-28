# Vim / Neovim
> nvim

## General

- https://mason-registry.dev/registry/list
- mason -> mason-lspconfig: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md

python environment: https://www.reddit.com/r/neovim/comments/14316t9/help_me_to_get_the_best_python_neovim_environment/

- https://github.com/stevearc/conform.nvim
  - Lightweight yet powerful formatter plugin for Neovim

- https://github.com/mfussenegger/nvim-lint
  - An asynchronous linter plugin for Neovim complementary to the built-in Language Server Protocol support.

fold / unfold
https://neovim.io/doc/user/fold.html
https://neovim.io/doc/user/fold.html

[How to generate a number sequence in file using vi or Vim?](https://stackoverflow.com/questions/9903660/how-to-generate-a-number-sequence-in-file-using-vi-or-vim)
> column sum sequence numbers column numbered list

```
:help v_g_CTRL-A

# to use a step count of 2
2g Ctrl-a
```

Formatter / prettier for neovim in lua:
- [Neovim - Null-ls: a quick explanation](https://www.youtube.com/watch?v=e3xxkEbhG0o)


Spellcheck / spell:

```vimscript
:spellr
```

- repeats the last spelling correction for all matches that was corrected

vimwiki:

Find what filetype is loaded in vim / how to know which filetype

```vimscript
:set filetype?
```

function to simplify keymappings:

```
-- Functional wrapper for mapping custom keybindings
-- https://blog.devgenius.io/create-custom-keymaps-in-neovim-with-lua-d1167de0f2c2

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end
local default_opts = { noremap = true, silent = true }
map("n", "<leader><tab>", "<cmd>b#<CR>", default_opts)
map("n", "<leader>h", ":nohlsearch<CR>", default_opts)
```


```
" Redir output to empty buffer [^5]
command! -nargs=+ -complete=command Redir let s:reg = @@ | redir @"> | silent execute <q-args> | redir END | new | pu | 1,2d_ | let @@ = s:reg
" [^5]: Dump the output of internal vim command into buffer (https://vi.stackexchange.com/questions/8378/dump-the-output-of-internal-vim-command-into-buffer)
```

Macro helpers to input common texts:

```
" js helpers
augroup jshelpers
    au! FileType javascript nnoremap <leader>c "cyiwoconsole.log(c)
augroup END

" auto create docs markdown helpers
augroup mdhelpers
    au!
    "" reference structure with a sequence number
    au FileType markdown nnoremap <leader>ri o[^1]: []()"+pT)
    au FileType markdown nnoremap <leader>rs :norm 0ll:let @n=0"nyiwo[^=n+1]: []()"+pT)
    "" code block: simple
    au FileType markdown nnoremap <leader>cc o``````kk
    au FileType markdown nnoremap <leader>cp o``````kk"+p
    "" code block: with file name
    au FileType markdown nnoremap <leader>ff o**``**``````kkkklll
    au FileType markdown nnoremap <leader>fp o**``**``````kk"+p
    "" link and paste at end
    au FileType markdown nnoremap <leader>i i[]()"+pT)
augroup END
```


associate different file types with extensions

```
augroup mdfiletypes
    " associate *.foo with bar filetype
    " do not override previouslly setted filetypes
    au!
    au BufNewFile,BufRead *.rmd setfiletype markdown
    au BufNewFile,BufRead Description setfiletype markdown
augroup END
```


---

Vim Snippets: https://github.com/honza/vim-snippets

- set a registry value: `:let @q=<any value>`
    - `q` is the registry

[how do I use a variable content as an argument for vim command?](https://superuser.com/questions/320395/how-do-i-use-a-variable-content-as-an-argument-for-vim-command)

```
:let $foo="whatever"
:let $bar=@a
```

```
:e $foo
:e $bar
```

- Vim recognizes `$` in commands and expands it
- `$bar` has the content of `a` registry/macro

### From Macro to Commands (with keybinding)[^2]

- ctrl + R ctrl-r <C-R> ^r in insert mode
- Insert the contents of a register
- edit a macro

- To paste the content of a macro saved in `q` reg, for example:
    - `i^R^Rq`: Press “i” to enter insert mode, then press CTRL-R twice, then press “q” to insert the contents of the “q” register. What ought to come out looks like this:
        - `^[`: literal escape
        - CTRL-R twice: insert that escape character code literally
    - or...
    - `"qp`: same result, but not in insert mode
    - `:put q` same result

- To save the characters back to `q` macro registry:
    - cursor at beginning
    - `"qy$`

- create a mapping from a macro:
    - `nnoremap <Leader>a ^R^Rq`


### Search / Replace

To perform search-replace in Vim easily, we can take advantage of quickfix and grep.

Say I want to substitute "define" with "describe" everywhere:

- :grep "define"
- :cfdo %s/define/describe/g | update
(see more in: https://twitter.com/learnvim/status/1277635983153008641?s=09)

We can reassign Vim's `:grep` with other tool. I am a fan of ripgrep (https://github.com/BurntSushi/ripgrep). In my vimrc, do this:

set grepprg=rg\ --vimgrep\ --smart-case\ --follow

Run:

grep "my-phrase"

It uses `rg` instead of `grep`. `:grep` uses quickfix. `:copen` to view results.

(more in: https://twitter.com/learnvim/status/1276917091472474112?s=09)

### Command line

When in command line mode, copy the word under the cursor and insert into the command line using <C-r> <C-w>.

## Git

### Tools / mergetool / diff tool

#### 1) Fugitive + Trouble

**[Resolve Git Merge Conflicts with Neovim and Fugitive!](https://www.youtube.com/watch?v=vpwJ7fqD1CE)**

vim-fugitive
- `Gvdiff`: normal diff from last version (last commit)
- `Gvdiffsplit!`: 3 way split
    - `buffers` to identify which
    - select diff from local or remote to be applied
        - Pointer on top of conflict text area:
            - `diffget [press-tab]`: show to select one of 3 buffers
        - (or) at buffer you want to select, press: `dp` (diff push)
    - `Gwrite` to stage conflict changes
- `Gitsign` stage a hunk of file

- lsp/troubble, jump between diagnostics (add shortcut)
    - e.g. `]d` next, `[d` prev

#### 2) git-conflict.nvim

https://github.com/akinsho/git-conflict.nvim
https://github.com/yorickpeterse/nvim-pqf

### Git workflow

[The ULTIMATE Git workflow using Neovim's Fugitive, Telescope & Git-Signs!](https://www.youtube.com/watch?v=IyBAuDPzdFY)

vim-fugitive
- `:Git`: status/staging area
    - `Git help`: list of options
    - select a file (pointer on top or visual area) and `-`: add a file
    - `=` show file changes
    - `<cr>` opens file
- `Gvdiff` over a file / open its diffs
    - `Gvdiff origin/master`
    - e.g. mapping `]c` `[c` next/prev changes

## Plugins

https://github.com/tpope/vim-eunuch: Vim sugar for the UNIX shell commands that need it the most

https://github.com/tpope/vim-unimpaired : unimpaired.vim: Pairs of handy bracket mappings

## Bulk rename files with vim

### Programs in shell

- (!) `moreutils` package: `vidir`
-  thameera / vimv
- https://github.com/laurent22/massren

### Pure Vim

[Bulk rename files with Vim ](https://vim.fandom.com/wiki/Bulk_rename_files_with_Vim)

```
:%s/.*/mv -i & &/g
:%s/.JPEG$/.jpg/g
```

Explanation[^3]:

```
:%s/.*/mv -i & &/g
```

- Replaces every line in the document (say, "line"), and replaces it by "mv -i line line". `.*` is a regex saying "any character, repeated any number of times". & means "what has been found".


```
:%s/.JPEG$/.jpg/g
```

- Searches for .JPEG at the end of any line (hence the $) and replaces it by .jpg

```
:%!bash
```

- sends the rename shell commands (that's why mv is prepended to each file name) to an external shell for execution.

### Plugins to rename

#### vim-dirvish

- https://github.com/justinmk/vim-dirvish/
    - vim dir tree (better than netwr)

bulk rename workflow with vim-dirvish

```
Workflow with dirvish:

    Visit any number of directories using dirvish, in Vim.

    Type x to add a file(s) to the arglist.

    Use :Shdo! mv {} {}.bk to generate a shell script from the arglist.

    Use regular Vim commands (and plugins) to edit the shell script.

    Run the shell script with Z!
```

## tmux integration

**`tmux.conf`**
```
# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
is_fzf="ps -o state= -o comm= -t '#{pane_tty}' \
  | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
# [^3]
bind -n C-j run "($is_vim && tmux send-keys C-j)  || \
                         ($is_fzf && tmux send-keys C-j) || \
                         tmux select-pane -D"
bind -n C-k run "($is_vim && tmux send-keys C-k) || \
                          ($is_fzf && tmux send-keys C-k)  || \
                          tmux select-pane -U"
tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"
bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
bind-key -T copy-mode-vi 'C-\' select-pane -l

# bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
# bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
# [^3]: [Tmux and Vim — even better together](https://www.bugsnag.com/blog/tmux-and-vim)
```

## config lua

```lua
local api = vim.api
local M = {}
-- function to create a list of commands and convert them to autocommands
-------- This function is taken from https://github.com/norcalli/nvim_utils
function M.nvim_create_augroups(definitions)
    for group_name, definition in pairs(definitions) do
        api.nvim_command('augroup '..group_name)
        api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
            api.nvim_command(command)
        end
        api.nvim_command('augroup END')
    end
end
```

other opts
```lua
vim.opt.hidden = true -- " allow [^13] 'E37: No write since last change (add ! to override)'. switch to a different buffer for referencing some code and switch back
```


## References

[^1]: [Vim: Tutorial on Customization and Configuration (2020)](https://youtu.be/JFr28K65-5E)
[^2]: [Master Vim Registers With Ctrl R](https://blog.aaronbieber.com/2013/12/03/master-vim-registers-with-ctrl-r.html)
[^3]: [Vim Batch Rename](https://stackoverflow.com/questions/30378569/vim-batch-rename)
