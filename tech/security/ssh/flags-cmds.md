# SSH: Important Flags and Commands

<!-- toc -->

- [`-T/-t` pseudo-terminal allocation](#-t-t-pseudo-terminal-allocation)

<!-- tocstop -->

## `-T/-t` pseudo-terminal allocation

```
-T      Disable pseudo-terminal allocation.

-t      Force pseudo-terminal allocation.  This can be  used  to
        execute  arbitrary screen-based programs on a remote ma‐
        chine, which can be very useful, e.g. when  implementing
        menu  services.   Multiple  -t options force tty alloca‐
        tion, even if ssh has no local tty.
```

The `-T` option for `ssh` tells it **not** to allocate a pseudo-TTY on the remote side. In other words:

* By default, when you run `ssh host`, SSH will try to give you an interactive terminal session (allocating a “PTY”).
* If you add `-T`, SSH will suppress that and just run whatever command (or subsystem) you’ve asked for, without trying to hook up your terminal to it.

Why it matters for things like Git:

* Git’s SSH transport isn’t an interactive shell — it’s just a protocol exchange. If SSH tries to allocate a PTY and the server won’t allow it (or you don’t need it), you’ll get warnings (or slowdowns).
* Using `ssh -T git@github.com` cleanly skips the TTY step, so Git commands go straight through.

Contrast:

* `-t` forces allocation of a pseudo-TTY.
* `-T` disables allocation of a pseudo-TTY.

So anytime you’re using SSH purely as a pipe for a non-interactive service (like Git, rsync in daemon mode, or a remote command), `-T` is the “right” flag to use.

Here are some concrete scenarios where `ssh -T` (disable pseudo-TTY allocation) comes in handy:

- **Test ssh access (in this example, at a gitolite server)**

```
❯ ssh -T gitcwnt-gubasso
hello gubasso, this is git@srv123465 running gitolite3 3.6.12-1 (Debian) on git 2.34.1

 R W	cwnt/docker-apps
 R W	cwnt/infra
 R W	cwnt/password-store
 R W	gubasso/password-store
 R W	gubasso/personal-notes
```

1. **Checking your GitHub (or GitLab) SSH setup**

   ```bash
   ssh -T git@github.com
   ```

   You’ll get a clean “Hi <username>! You’ve successfully authenticated…” response instead of any shell prompt, since GitHub only speaks the Git protocol, not an interactive shell.

2. **Running a one-off remote command in a script**

   ```bash
   ssh -T user@server.example.com "uptime"
   ```

   Because you’re just sending a command and capturing its output, you don’t need—or want—a TTY.

3. **Non-interactive port-forwarding (with `-N`)**

   ```bash
   ssh -N -T -L 8080:localhost:80 user@remote.example.com
   ```

   * `-N` tells SSH to not run a remote command (just forward ports)
   * `-T` ensures no TTY is allocated
     This is ideal for background tunnels.

4. **Piping data through SSH**

   ```bash
   tar czf - /some/dir | ssh -T user@backup.example.com "cat > /backups/dir.tar.gz"
   ```

   You’re streaming the tarball over SSH; no interactive shell is needed.

5. **Using `rsync` over SSH when you’ve customized SSH options**

   ```bash
   rsync -avz -e "ssh -T -i ~/.ssh/keys/id_ed25519" ./local/ user@host:/remote/
   ```

   Passing `-T` in the `-e` string ensures rsync’s SSH tunnel won’t try to grab a TTY.

---

In each of these cases, omitting `-T` could lead SSH to attempt a TTY allocation, which either fails (on servers that forbid PTYs) or prints unwanted warnings. Disabling the TTY keeps your data streams clean and your automation scripts predictable.
