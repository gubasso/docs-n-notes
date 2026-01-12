# US AltGr-International Keymap for Arch Linux TTY (Wayland/KDE Independent)

## Goal

Keep `KEYMAP=us` during the Arch installation, then—after your system is installed—switch the **Linux virtual console (TTY)** to a **US “AltGr International, nodeadkeys”** behavior:

* Normal `'`, `"`, `` ` ``, `~` type normally.
* **Accents only activate when you use Right-Alt (AltGr)**, then the accent key, then the letter.

Because the Linux console uses **kbd** keymaps (not XKB variants), this requires installing a **ready-made console keymap file** that implements the behavior.

---

## Recommended ready-made console keymap (trusted community baseline)

The most practical, widely reused solution in the Arch community is the **Max Klinger**-style console map commonly distributed as:

* `us-altgr-intl-nodeadkeys.map`

It is specifically used to achieve your desired behavior on the **TTY** and avoid common pitfalls (notably broken Ctrl behavior) seen in naïve keymap edits.

### Important download links (ready to use)

**1) Direct “raw file” download (ready-made keymap):**

```text
https://raw.githubusercontent.com/ginkel/us-intl-altgr/main/us-altgr-intl-nodeadkeys.map
```

**2) Project repository (includes packaging/PKGBUILD option):**

```text
https://github.com/ginkel/us-intl-altgr
```

---

## Option A: Download the keymap file and install locally (fastest, no packaging)

### 1) Ensure console tooling is present

```bash
sudo pacman -S --needed kbd
```

### 2) Install the keymap under /usr/local

```bash
sudo install -d /usr/local/share/kbd/keymaps

sudo curl -L \
  -o /usr/local/share/kbd/keymaps/us-altgr-intl-nodeadkeys.map \
  "https://raw.githubusercontent.com/ginkel/us-intl-altgr/main/us-altgr-intl-nodeadkeys.map"
```

### 3) Test immediately (no reboot)

```bash
sudo loadkeys /usr/local/share/kbd/keymaps/us-altgr-intl-nodeadkeys.map
```

### 4) Persist for all TTYs via /etc/vconsole.conf

```bash
sudoedit /etc/vconsole.conf
```

Set:

```ini
KEYMAP=/usr/local/share/kbd/keymaps/us-altgr-intl-nodeadkeys.map
FONT=ter-v32b
```

Apply without reboot:

```bash
sudo systemctl restart systemd-vconsole-setup.service
```

---

## Option B: Install as a pacman-managed package (cleanest lifecycle)

This is the best approach if you want `pacman -Rns ...` to cleanly remove it later.

### 1) Install build prerequisites

```bash
sudo pacman -S --needed base-devel git
```

### 2) Build and install from the repo

```bash
git clone https://github.com/ginkel/us-intl-altgr.git
cd us-intl-altgr
makepkg -si
```

### 3) Configure vconsole

Depending on where the package installs the map, you can typically use either a keymap name or a full path.

Start by locating it:

```bash
find /usr/share/kbd/keymaps -type f -name '*altgr*intl*nodead*' -o -name 'us-altgr-intl-nodeadkeys*'
```

Then set `/etc/vconsole.conf` accordingly, for example:

```ini
KEYMAP=us-altgr-intl-nodeadkeys
FONT=ter-v32b
```

Apply:

```bash
sudo systemctl restart systemd-vconsole-setup.service
```

---

## Make it work at the early-boot LUKS passphrase prompt (recommended)

If you want the same layout available during early boot (e.g., at `sd-encrypt`), rebuild initramfs after finalizing `/etc/vconsole.conf`:

```bash
sudo mkinitcpio -P
```

---

## Quick validation tests (TTY)

After applying the keymap, test on a TTY:

* Normal `'` prints `'`
* Normal `"` prints `"`
* **AltGr + '**, then `e` → `é`
* **AltGr + `**, then `a`→`à`
* **AltGr + ~**, then `n` → `ñ`
* **AltGr + "**, then `u` → `ü`

(Exact sequences can vary slightly by map, but the defining feature is: accents require AltGr; punctuation does not become dead-key by default.)

---

## Rollback plan (if you ever need it)

### Temporary rollback (current console session only)

```bash
sudo loadkeys us
```

### Permanent rollback

Edit `/etc/vconsole.conf` back to:

```ini
KEYMAP=us
FONT=ter-v32b
```

Apply:

```bash
sudo systemctl restart systemd-vconsole-setup.service
sudo mkinitcpio -P
```
