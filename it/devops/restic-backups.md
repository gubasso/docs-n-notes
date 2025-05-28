# Restic

- https://restic.net/
- https://restic.readthedocs.io/en/latest/
- [Restic Complete Guide](https://www.youtube.com/playlist?list=PLFxkuUNT-SE0Hy2X00jgBBTBg0Z8cFahy)
- https://github.com/restic/restic
- https://wiki.archlinux.org/title/Restic

## General


```
      -r, --repo repository            repository to backup to or restore from (default: $RESTIC_REPOSITORY)
      --repository-file file       file to read the repository location from (default: $RESTIC_REPOSITORY_FILE)
      --password-command command   shell command to obtain the repository password from (default: $RESTIC_PASSWORD_COMMAND)
```

- -r is it the location of the backup (destination, actual backup)

Calling restic in this way, the shell starts `gpg` and provides restic with file descriptor that it can read like a file.[^1]

```
restic --password-file <( gpg --decrypt path-to-key.gpg ) backup [...]
gpg --decrypt blablabla | restic -r /path/to/repo snapshots
```

[^1]: https://github.com/restic/restic/issues/533 "Support unattended encrypted backups without key disclosure #533"


