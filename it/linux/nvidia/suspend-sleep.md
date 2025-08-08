# Nvidia: suspend / sleep

Below is a concise guide to suspending (sleeping) your Arch Linux system under Niri WM, covering the commands you’ll use, integrating them into your Niri config, handling NVIDIA hardware quirks, and Polkit permissions.

## Key systemd commands for suspend, hibernate, and hybrid-sleep

* **Suspend to RAM**
  Run:

  ```bash
  systemctl suspend
  ```

  This enqueues the `suspend.target` unit and should just work out of the box on Arch Linux with systemd-logind running ([ArchWiki][1], [ArchWiki][1]).
* **Alternate invocation via loginctl**
  You can also call:

  ```bash
  loginctl suspend
  ```

  which triggers the same action through logind’s D-Bus interface ([Unix & Linux Stack Exchange][2]).
* **Hibernate to disk**

  ```bash
  systemctl hibernate
  ```

  (May require following the ArchWiki’s hibernation setup guide if it doesn’t work immediately.) ([ArchWiki][1])
* **Hybrid-sleep (suspend + hibernate)**

  ```bash
  systemctl hybrid-sleep
  ```

  Writes to both RAM and swap so you can recover after a power loss ([ArchWiki][1]).

## Binding a sleep key in your Niri WM config

Niri’s key bindings live in the `binds {}` section of your config (in KDL format). To bind the XF86Sleep key to suspend:

```kdl
binds {
    XF86Sleep { spawn "systemctl" "suspend"; }
}
```

* The `spawn` action runs a binary without a shell, so you must separate arguments (binary first, then each argument) ([GitHub][3]).
* If you prefer a custom key combo, replace `XF86Sleep` with something like `Mod+Shift+S` ([GitHub][3]).
* Use a tool like `wev` to confirm the exact key name if needed ([GitHub][3]).

## NVIDIA Ada 3000-specific suspend tips

On systems with NVIDIA GPUs you may need the NVIDIA power services and init-rd hooks:

1. **Enable systemd services**

   ```bash
   systemctl enable nvidia-suspend.service \
                     nvidia-hibernate.service \
                     nvidia-resume.service
   ```
2. **Add hooks to `/etc/mkinitcpio.conf`**
   Include `resume` and NVIDIA hooks in `HOOKS=(... resume nvidia ...)` and regenerate your initramfs.

Without these, `systemctl suspend` may black-screen but immediately wake ([Arch Linux Forums][4]).

## Polkit: allowing suspend without password

By default, active local sessions can suspend without extra auth, but if you face “authentication required” prompts:

1. **Install Polkit**

   ```bash
   pacman -S polkit
   ```
2. **Create a rule** in `/etc/polkit-1/rules.d/50-suspend.rules`:

   ```js
   polkit.addRule(function(action, subject) {
       if (action.id == "org.freedesktop.login1.suspend" &&
           subject.isInGroup("wheel")) {
           return polkit.Result.YES;
       }
   });
   ```

   This grants wheel-group users passwordless suspend ([ArchWiki][5]).

---

With these steps, hitting your designated key in Niri will correctly invoke `systemctl suspend` (or your chosen power command), even on NVIDIA-equipped hardware, and without unwanted password prompts.

[1]: https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate?utm_source=chatgpt.com "Power management/Suspend and hibernate - ArchWiki"
[2]: https://unix.stackexchange.com/questions/490719/how-does-systemctl-suspend-work?utm_source=chatgpt.com "How does systemctl suspend work? - Unix & Linux Stack Exchange"
[3]: https://github.com/YaLTeR/niri/wiki/Configuration%3A-Key-Bindings "Configuration: Key Bindings · YaLTeR/niri Wiki · GitHub"
[4]: https://bbs.archlinux.org/viewtopic.php?id=304972&utm_source=chatgpt.com "Suspend and Hibernate not working / Laptop Issues / Arch Linux Forums"
[5]: https://wiki.archlinux.org/title/Polkit?utm_source=chatgpt.com "polkit - ArchWiki"
