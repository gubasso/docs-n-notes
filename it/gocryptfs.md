# gocryptfs

> data at rest encryption

<!-- toc -->

- [1. Introduction to gocryptfs](#1-introduction-to-gocryptfs)
- [2. Prerequisites](#2-prerequisites)
- [3. Installation (Arch Linux)](#3-installation-arch-linux)
- [4. Initializing an Encrypted Directory](#4-initializing-an-encrypted-directory)
- [5. Mounting and Unmounting](#5-mounting-and-unmounting)
  - [5.1 Manual Mount](#51-manual-mount)
  - [5.2 Unmount](#52-unmount)
- [6. Automating Mount Checks in Bash](#6-automating-mount-checks-in-bash)
- [7. Advanced Usage](#7-advanced-usage)
- [8. GUI Front-End: SiriKali](#8-gui-front-end-sirikali)
- [9. Best Practices & Troubleshooting](#9-best-practices--troubleshooting)
- [References](#references)

<!-- tocstop -->

## 1. Introduction to gocryptfs

gocryptfs implements **file-based encryption** entirely in user space, mounting an encrypted directory (`CIPHERDIR`) to a plaintext view (`MOUNTPOINT`) via FUSE. It was designed to address security concerns in earlier tools like EncFS and has matured through extensive stress testing and correctness checks ([Arch Manual Pages][3], [maketecheasier][4]).

---

## 2. Prerequisites

* **FUSE support**: gocryptfs requires a FUSE implementation (`fuse3` or `fuse2`) to be installed and the kernel module loaded ([ArchWiki][1]).
* **Unix-like OS**: Linux (native), macOS (beta), or WSL on Windows.
* **Privileges**: Ability to install packages and load kernel modules (typically via `sudo`).

---

## 3. Installation (Arch Linux)


```bash
sudo pacman -S gocryptfs
```

## 4. Initializing an Encrypted Directory

1. **Create directories** for your encrypted data and its mount point:

   ```bash
   mkdir -p ~/vault_encrypted
   mkdir -p ~/vault_plain
   ```
2. **Initialize the encrypted directory**:

   ```bash
   gocryptfs -init ~/vault_encrypted
   ```

   This generates a `gocryptfs.conf` file containing your encrypted master key and salt, secured by your passphrase ([Arch Manual Pages][6], [ArchWiki][1]).

3. **Change passphrase** (optional):

   ```bash
   gocryptfs -passwd ~/vault_encrypted
   ```

   This prompts for the current and new passphrases, backing up the old config to `gocryptfs.conf.bak` ([Arch Manual Pages][6], [ArchWiki][1]).

---

## 5. Mounting and Unmounting

### 5.1 Manual Mount

```bash
gocryptfs ~/vault_encrypted ~/vault_plain
```

* To allow other users to access the mount, use:

  ```bash
  gocryptfs -o allow_other ~/vault_encrypted ~/vault_plain
  ```

  (Ensure `user_allow_other` is enabled in `/etc/fuse.conf`.) ([Arch Manual Pages][6], [Arch Manual Pages][3])

### 5.2 Unmount

```bash
fusermount -u ~/vault_plain
# or
umount ~/vault_plain
```

Unmounting flushes all writes and detaches the decrypted view ([Arch Manual Pages][6], [Arch Manual Pages][3]).

---

## 6. Automating Mount Checks in Bash

To avoid duplicate mounts, use a script that checks if the mount point is active before mounting ([Baeldung][7], [Stack Overflow][8]):

```bash
#!/usr/bin/env bash

MOUNTPOINT=~/vault_plain
CRYPTDIR=~/vault_encrypted

if mountpoint -q "$MOUNTPOINT"; then
  echo "Vault already mounted at $MOUNTPOINT"
else
  echo "Mounting vault..."
  gocryptfs -o allow_other "$CRYPTDIR" "$MOUNTPOINT"
fi
```

* `mountpoint -q`: checks if the directory is a mount point.
* Alternatively, `grep -q " $MOUNTPOINT " /proc/mounts`.

---

## 7. Advanced Usage

* **Reverse mode** (`-reverse`): Mount a plaintext directory as an encrypted view, useful for on-the-fly encrypted backups. It uses deterministic AES-SIV rather than AES-GCM to ensure stable filenames ([Nuetzlich][9], [LinuxLinks][2]).
* **Long filename support** (`-longnames`): Enable handling of base64-encoded names up to 255 bytes by storing overflow names in `.name` files (default enabled) ([Go Packages][10], [GitHub][11]).
* **Filename padding**: Random padding obfuscates exact file sizes by padding encrypted filenames—helpful for privacy on cloud storage ([Nuetzlich][12]).
* **Master key mounting** (`-masterkey`): Mount directly with a raw master key (in hex or via `stdin`) if you’ve lost your passphrase but retained the key. Note the security risk of passing keys on the command line ([LinuxLinks][2]).

---

## 8. GUI Front-End: SiriKali

[SiriKali](https://mhogomchungu.github.io/sirikali/) is a Qt/C++ GUI that manages gocryptfs (and other FUSE backends) visually:

1. **Install via Flatpak**:

   ```bash
   flatpak install flathub io.github.mhogomchungu.sirikali
   ```
2. **Launch SiriKali**, click **“Add”**, choose the gocryptfs backend, configure your encrypted folder and mount point, then click **Mount** or **Unmount** as needed ([Flathub - Apps for Linux][13], [Mhogo Mchungu][14]).

---

## 9. Best Practices & Troubleshooting

* **Back up your `gocryptfs.conf`** outside the encrypted directory to prevent total data loss if it’s corrupted ([ArchWiki][1]).
* **Use a strong passphrase** to leverage the full strength of Scrypt key derivation ([Nuetzlich][15]).
* **Always unmount** before shutting down to avoid possible corruption.
* **FUSE errors** (e.g., “Permission denied”): ensure the `fuse` module is loaded (`sudo modprobe fuse`) and that your user is in the `fuse` group ([ArchWiki][1]).

---

## References

[1]: https://wiki.archlinux.org/title/Gocryptfs?utm_source=chatgpt.com "gocryptfs - ArchWiki"
[2]: https://www.linuxlinks.com/gocryptfs-encrypted-overlay-filesystem-go/?utm_source=chatgpt.com "gocryptfs – encrypted overlay filesystem written in Go"
[3]: https://man.archlinux.org/man/gocryptfs.1?utm_source=chatgpt.com "gocryptfs(1) - Arch manual pages"
[4]: https://maketecheasieraw.pages.dev/posts/how-to-encrypt-files-with-gocryptfs/?utm_source=chatgpt.com "How To Encrypt Files With Gocryptfs | maketecheasier"
[5]: https://github.com/rfjakob/gocryptfs?utm_source=chatgpt.com "rfjakob/gocryptfs: Encrypted overlay filesystem written in Go - GitHub"
[6]: https://man.archlinux.org/man/gocryptfs.1.raw?utm_source=chatgpt.com "Arch manual pages"
[7]: https://www.baeldung.com/linux/bash-is-directory-mounted?utm_source=chatgpt.com "Check if Directory Is Mounted in Bash | Baeldung on Linux"
[8]: https://stackoverflow.com/questions/9422461/check-if-directory-mounted-with-bash?utm_source=chatgpt.com "linux - Check if directory mounted with bash - Stack Overflow"
[9]: https://nuetzlich.net/gocryptfs/reverse_mode_crypto/?utm_source=chatgpt.com "Reverse Mode Cryptography - gocryptfs - nuetzlich.net"
[10]: https://pkg.go.dev/github.com/derdonut/gocryptfs?utm_source=chatgpt.com "gocryptfs command - github.com/derdonut/gocryptfs - Go ... - Go Packages"
[11]: https://github.com/rfjakob/gocryptfs/blob/master/README.md?utm_source=chatgpt.com "gocryptfs/README.md at master · rfjakob/gocryptfs · GitHub"
[12]: https://nuetzlich.net/gocryptfs/forward_mode_crypto/?utm_source=chatgpt.com "gocryptfs Cryptography - nuetzlich.net"
[13]: https://flathub.org/apps/io.github.mhogomchungu.sirikali?utm_source=chatgpt.com "Install SiriKali on Linux | Flathub"
[14]: https://mhogomchungu.github.io/sirikali/?utm_source=chatgpt.com "SiriKali works on Linux, macOS and Microsoft Windows Operating Systems"
[15]: https://nuetzlich.net/gocryptfs/?utm_source=chatgpt.com "gocryptfs - simple. secure. fast. - nuetzlich.net"
