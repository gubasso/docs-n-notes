# Vim plugin: Fugitive

## General

## List commits for the current file

Here’s how to get a history **just for the current file** in Vim Fugitive

### File-specific history with `:Gclog -- %`

Run this in the buffer of the file you care about:

```vim
:Gclog -- %
:copen
```

* The `-- %` tells Fugitive to pass *only* the current file (`%`) to `git log`, populating your quickfix list with commits that touched that file .

### Alternative: `:0Gclog`

If you prefer to load the full history into quickfix without immediately opening the first result:

```vim
:0Gclog
```

* Here, `0` is treated as “the whole file,” so Fugitive shows every commit for that file .
* Navigate between entries with `]q` (next) and `[q` (previous) .

### Limiting history scope

To fetch only the last *N* commits, supply a range before `-- %`:

```vim
:Gclog -10 -- %
```

* This loads the ten most recent commits for the file into quickfix .
* The original `:Glog` command (the predecessor of `:Gclog`) supports the same syntax:

  ```vim
  :Glog -- %
  ```

  .

---

Fugitive’s `:Glog` (and its newer alias `:Gclog`) is just a thin wrapper around:

```bash
git log <file>
```

—so by default it’s already scoped to the current file. If you provide your own `--` without `%`, it assumes you want the full repo log, which is why `:Gclog` by itself falls back to the project history .

Tim Pope renamed `:Glog` to `:Gclog` to emphasize that it’s not the “definitive” log interface (making way for a proper `:Git log` command) and to avoid confusion when arguments are dropped . When you explicitly give it `-- %`, it restores the file-only behavior .

### Quick navigation and diffs

* Press <Enter> on any quickfix entry to open that file revision in a read-only buffer .
* To view a side-by-side diff against your working copy (or against another commit), use:

  ```vim
  :Gdiffsplit <SHA>
  ```

  .

### Inspecting a specific file revision

```vim
:Gedit {commit}:{file}
```

E.g. to see how the file looked three commits ago:

```vim
:Gedit HEAD~3:%
``` :contentReference[oaicite:2]{index=2}
```

## Fugitive + Trouble

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
