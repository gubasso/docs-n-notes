# gocryptfs

- data at rest encryption:
    - gocryptfs <https://nuetzlich.net/gocryptfs/> / <https://mhogomchungu.github.io/sirikali/> (gui)
    - <https://wiki.archlinux.org/title/Gocryptfs>
- [Check if Directory is Mounted in Bash](https://www.baeldung.com/linux/bash-is-directory-mounted)
    - to use with gocryptfs, script to check if vault is already mounted


Initialize the gocryptfs filesystem in the encrypted directory:

```sh
gocryptfs -init /path/to/encrypted-dir
```

