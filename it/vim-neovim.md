# Vim / Neovim
> nvim

<!-- vim-markdown-toc GFM -->

* [General](#general)
    * [From Macro to Commands (with keybinding)[^2]](#from-macro-to-commands-with-keybinding2)
    * [Search / Replace](#search--replace)
    * [Command line](#command-line)
* [Plugins](#plugins)
* [Bulk rename files with vim](#bulk-rename-files-with-vim)
    * [Programs in shell](#programs-in-shell)
    * [Pure Vim](#pure-vim)
    * [Plugins to rename](#plugins-to-rename)
        * [vim-dirvish](#vim-dirvish)
* [References](#references)

<!-- vim-markdown-toc -->

## General

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


## References

[^1]: [Vim: Tutorial on Customization and Configuration (2020)](https://youtu.be/JFr28K65-5E)
[^2]: [Master Vim Registers With Ctrl R](https://blog.aaronbieber.com/2013/12/03/master-vim-registers-with-ctrl-r.html)
[^3]: [Vim Batch Rename](https://stackoverflow.com/questions/30378569/vim-batch-rename)
