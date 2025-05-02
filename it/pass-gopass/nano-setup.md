# Nano Setup for Gopass


Here’s a quick way to keep your usual nano settings intact while disabling backup files **only** when gopass invokes nano:

## 1. Create a dedicated nanorc for gopass

Put just the single line below into, say, `~/.config/gopass/nanorc`:

```nanorc
unset backup
```

This tells nano **not** to write any `filename~` backups when it saves ([Nano][1]).

## 2. Point gopass at that rcfile

Configure gopass to launch nano with your custom rcfile (and nowhere else) by running:

```bash
gopass config edit.editor "nano --rcfile ~/.config/gopass/nanorc"
```

This uses gopass’s built-in `config` command to set the per-user `edit.editor` value ([Arch Manual Pages][2], [Nano][3]). Only gopass will pass the `--rcfile` flag, so your normal `~/.nanorc` (with its backups or other settings) remains untouched.

## 3. (Optional) Use a wrapper script

If you prefer, you can encapsulate the above in a tiny script:

```bash
#!/usr/bin/env bash
nano --rcfile ~/.config/gopass/nanorc "$@"
```

Save that as `~/bin/gopass-nano`, `chmod +x ~/bin/gopass-nano`, then tell gopass:

```bash
gopass config edit.editor "~/bin/gopass-nano"
```

Either approach ensures that **only** your gopass-edited secrets get the `unset backup` behavior, while you keep full nano functionality elsewhere.

[1]: https://www.nano-editor.org/dist/v1.2/nanorc.5.html?utm_source=chatgpt.com "Manpage of NANORC - nano-editor.org"
[2]: https://man.archlinux.org/man/gopass.1.en?utm_source=chatgpt.com "gopass(1) - Arch manual pages"
[3]: https://www.nano-editor.org/dist/latest/nanorc.5.html?utm_source=chatgpt.com "NANORC"
