# Vim / Neovim

## General


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

## Resources

- Vim: Tutorial on Customization and Configuration (2020) https://youtu.be/JFr28K65-5E
