# Custom keymap Caps Lock ESC switch (TTY/Console)

Here's how you can swap Caps Lock and Esc on a Void Linux virtual console and have it survive reboots.

## Summary

You’ll create a small custom keymap that tells the console to treat Scancode 1 as Caps Lock and Scancode 58 as Escape, load it immediately with `loadkeys`, and then persist it by either invoking `loadkeys` in `/etc/rc.local` (sourced by runit) or installing the map under `/usr/share/kbd/keymaps` and pointing `/etc/rc.conf`’s `KEYMAP` variable at it.

## 1. Create and test your custom keymap

### 1.1. Identify your keycodes

In a pure-text console (Ctrl + Alt + F2…F6), run:

```bash
sudo showkey
```

Press **Esc** and **Caps Lock** to see their scancodes (typically **1** and **58**, respectively). ([unix.stackexchange.com][1])

### 1.2. Write the swap mapping

Create `/etc/console-caps-esc.map` with these two lines:

```text
include "/usr/share/kbd/keymaps/i386/qwerty/us.map.gz"
keycode 1 = Caps_Lock
keycode 58 = Escape
```

This tells the kernel console to swap the two keys. ([unix.stackexchange.com][1])

### 1.3. Load immediately

Apply it now with:

```bash
sudo loadkeys /etc/console-caps-esc.map
```

This updates the translation table for all virtual consoles until reboot. ([unix.stackexchange.com][1])

According to the `loadkeys` manual, once loaded it affects every TTY and persists until the next reboot. ([man.voidlinux.org][2])

## 2. Make the swap persistent

Void Linux (runit-based) doesn’t use systemd’s `/etc/vconsole.conf` by default, but instead:

### 2.1. Option A: `/etc/rc.local`

Void sources `/etc/rc.local` in runit stage 2, making it perfect for boot-time commands. ([docs.voidlinux.org][3])

1. Create or edit `/etc/rc.local`:

   ```bash
   sudo vi /etc/rc.local
   ```
2. Add:

   ```sh
   #!/bin/sh
   loadkeys /etc/console-caps-esc.map
   ```
3. Make it executable:

   ```bash
   sudo chmod +x /etc/rc.local
   ```

On every reboot, runit will invoke this and reapply your mapping. ([docs.voidlinux.org][3])

### 2.2. Option B: Custom keymap in `/etc/rc.conf`

Void’s `/etc/rc.conf` supports a `KEYMAP` variable pointing to a keymap under `/usr/share/kbd/keymaps`. ([docs.voidlinux.org][3])

1. Copy your map into the keymaps tree (e.g. under a “personal” directory):

   ```bash
   sudo mkdir -p /usr/share/kbd/keymaps/personal
   sudo cp /etc/console-caps-esc.map /usr/share/kbd/keymaps/personal/swapCapsEsc.map
   ```

   ([linuxquestions.org][4])
2. Edit `/etc/rc.conf` and set:

   ```ini
   KEYMAP="personal/swapCapsEsc"
   ```

   At boot, Void will essentially run `loadkeys personal/swapCapsEsc.map`. ([docs.voidlinux.org][3])

## 3. Notes and alternatives

* Some systemd-based distros let you add a `KEYMAP_CORRECTIONS="swapCapsEsc"` line to `/etc/vconsole.conf` and have udev apply it at boot ([wiki.archlinux.org][5]), but Void relies on `rc.conf` and `loadkeys` instead.
* On Debian/Ubuntu you can also use `localectl set-keymap --no-convert us` (and rebuild initramfs) to persist console layouts ([unix.stackexchange.com][6]).

With either `/etc/rc.local` or the `KEYMAP` method in `/etc/rc.conf`, your Caps Lock and Esc keys will remain swapped every time you boot into a TTY.

[1]: https://unix.stackexchange.com/questions/266817/how-to-reverse-esc-and-caps-lock-on-tty "console - How to reverse ESC and CAPS_LOCK on TTY - Unix & Linux Stack ..."
[2]: https://man.voidlinux.org/loadkeys.1 "loadkeys (1) - Void Linux manpages"
[3]: https://docs.voidlinux.org/config/rc-files.html "rc.conf, rc.local and rc.shutdown - Void Linux Handbook"
[4]: https://www.linuxquestions.org/questions/blog/smilingfrog-584819/swapping-the-escape-and-caps-lock-in-console-37326/ "Swapping the Escape and Caps Lock in console"
[5]: https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration "Linux console/Keyboard configuration - ArchWiki"
[6]: https://unix.stackexchange.com/questions/75519/how-to-set-default-console-keyboard-layout-in-arch-linux "How to set default console keyboard layout in Arch Linux?"
