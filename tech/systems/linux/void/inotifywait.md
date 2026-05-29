# inotifywait

Below is a line-by-line breakdown of:

```sh
inotifywait -q -e create "$(dirname "$SOCK")" --format '' "${SOCK}" >&3
```

---

## 1. `inotifywait` – blocking on inotify events

`inotifywait` is a command-line front-end to the Linux kernel’s inotify subsystem. It opens one or
more watches, then **blocks** until one of the specified events occurs on a watched path, making it
ideal for shell scripts that need to wait for filesystem changes ([man7.org][1]).

---

## 2. `-q` / `--quiet` – suppress setup messages

- **`-q` once**: don’t print the usual “Setting up watches… Watches established” banner.
- **`-q` twice**: silence _all_ output except fatal errors. Here we use it once to avoid spamming
  the TTY with setup logs but still allow the eventual readiness byte to flow through
  ([man7.org][1]).

---

## 3. `-e create` – listen _only_ for creation events

- **`-e create`** restricts the watch to **“create”** events, i.e. when a file or directory is newly
  created in a watched directory ([man7.org][1]).
- Among the many inotify events (`modify`, `delete`, `moved_to`, etc.), **create** fires exactly
  when `$SOCK` appears ([man7.org][1]).

---

## 4. `--format ''` – send _no_ event text to stdout

By default inotifywait would print lines like:

```txt
/path/to/dir CREATE socket
```

The `--format` flag lets you specify a `printf`-style template for output. An empty string (`''`)
means “print nothing” (though still exit with status 0 on the event), so all you get is the exit
code and—critically—**one byte of output** (a newline) to stdout ([man7.org][1]).

---

## 5. Paths to watch

```sh
"$(dirname "$SOCK")"   "${SOCK}"
```

1. **`$(dirname "$SOCK")`**

   - `dirname` strips off the final component of a path, yielding the _parent directory_.
   - If `SOCK=/run/user/1000/wayland-1`, then `dirname "$SOCK"` → `/run/user/1000` ([Linux Die][2]).

2. **`"${SOCK}"`**

   - You can pass multiple arguments to inotifywait. Here it also opens a watch on the full socket
     path.
   - If the file isn’t there yet, the directory watch catches the creation. If it already exists
     (e.g. on a restart), the direct-file watch ensures immediate success.

---

## 6. Command substitution – expanding `dirname` before watch

The `$(…)` form runs its contents in a subshell, captures its stdout, strips trailing newlines, and
substitutes it in place.

```sh
dirname "$SOCK"
```

is thus evaluated _before_ inotifywait runs, giving it the directory to watch ([GNU][3]).

---

## 7. `>&3` – redirect stdout into file descriptor 3

- **`>&3`** means “take this command’s standard output (FD 1) and send it to FD 3 instead.”
- In our Dinit wrapper, Dinit passed us an open pipe on FD 3; writing any byte to it (even an empty
  line) tells Dinit “I’m ready” via its **ready-notification** mechanism.
- This is plain Bourne-shell I/O redirection: `[n]>&word` duplicates output FD word onto FD n (or,
  if `n` is omitted, duplicates STDOUT) ([GNU][4]).

If you ran a small script:

```sh
#!/bin/bash
echo hello >&3
```

and started it with `3>out.txt`, you’d see `out.txt` contain “hello” ([Stack Overflow][5]).

---

## 8. How it all ties together

1. **Start** `niri` in background.
2. **Block** on `inotifywait…` until the Wayland socket file appears in its parent directory.
3. **Quietly** emit exactly one byte (newline) on stdout, **redirected** into FD 3.
4. **Exit** with code 0—Dinit sees the ready byte, marks `niri` as started, and immediately spins up
   Waybar (and any other `depends-on` services) with no polling loops or fixed sleeps.

---

### TL;DR

- `inotifywait` uses the kernel’s event API to block until the socket is created.
- `-q -e create --format ''` makes that wait silent and precise.
- `$(dirname "$SOCK")` watches the directory; `"${SOCK}"` covers the exact file.
- `>&3` writes the ready signal into Dinit’s pipe.

This yields an **event-driven**, **zero-polling**, **fully supervised** startup notification for
your compositor.

[1]: https://www.man7.org/linux/man-pages/man1/inotifywait.1.html "inotifywait(1) - Linux manual page"
[2]: https://linux.die.net/man/1/dirname?utm_source=chatgpt.com "dirname (1) - Linux man page"
[3]: https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html?utm_source=chatgpt.com "Command Substitution (Bash Reference Manual)"
[4]: https://www.gnu.org/software/bash/manual/html_node/Redirections.html "Redirections (Bash Reference Manual)"
[5]: https://stackoverflow.com/questions/7082001/how-do-file-descriptors-work?utm_source=chatgpt.com "bash - How do file descriptors work? - Stack Overflow"
