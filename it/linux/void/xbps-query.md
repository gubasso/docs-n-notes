# xbps-query

Here’s how to search for packages on Void Linux using the `xbps-query` utility (part of the XBPS package manager):

* **Remote search** (in repositories): use `-R` (repositories) and `-s` (search).
* **Local search** (among all installed packages): use `-s` without `-R`.
* **Local only manually installed** (exclude dependencies): list manual packages.

---

## 1. Remote Search (Repositories)

To search for packages available in the configured repositories (remote), use:

```bash
xbps-query -Rs <pattern>
```

* `-R` tells XBPS to query the remote repositories.
* `-s` specifies a search operation by package name or regex.

Example:

```bash
xbps-query -Rs firefox
```

This will list all `firefox` packages available for installation, along with versions and descriptions ([docs.voidlinux.org][1])([commandexamples.com][2]).

---

## 2. Local Search (All Installed)

To search among all packages currently installed on your system (including dependencies), omit `-R`:

```bash
xbps-query -s <pattern>
```

* Without `-R`, `xbps-query` defaults to searching the local package database.
* You can also list *all* installed packages with:

  ```bash
  xbps-query --list-pkgs
  ```

Example:

```bash
xbps-query -s pipewire
```

This finds any installed packages matching “pipewire” ([docs.voidlinux.org][1])([commandexamples.com][2]).

---

## 3. Local Only Manually Installed (Explicit)

To list only the packages you installed directly (i.e., *not* pulled in as dependencies), use:

```bash
xbps-query --list-manual-pkgs
```

or its shorthand:

```bash
xbps-query -m
```

This shows the “root” packages you explicitly requested, which is useful for auditing or tidying up unused packages ([commandexamples.com][2])([de.wikipedia.org][3]).

---

### Quick Reference

| Scope                                  | Command                                |
| -------------------------------------- | -------------------------------------- |
| Remote (all repos)                     | `xbps-query -Rs <pattern>`             |
| Local (all installed)                  | `xbps-query -s <pattern>`              |
| List all installed packages            | `xbps-query --list-pkgs`               |
| Local only manually installed packages | `xbps-query --list-manual-pkgs` (`-m`) |

---

#### Additional Tips

* **Show package details** (local or remote):

  ```bash
  xbps-query --show <pkg> [--repository]
  ```

  Add `--repository` to show remote info ([commandexamples.com][2]).

* **List files in a package**:

  ```bash
  xbps-query -f <pkg>
  ```

  Useful when you need to locate installed files ([docs.voidlinux.org][1]).

With these commands, you can effectively discover packages across remote repos, on your system, and isolate those you explicitly installed.

[1]: https://docs.voidlinux.org/xbps/index.html "XBPS Package Manager - Void Linux Handbook"
[2]: https://commandexamples.com/linux/xbps-query "Examples of xbps-query Command in Linux - Command Examples"
[3]: https://de.wikipedia.org/wiki/Xbps "Xbps"

