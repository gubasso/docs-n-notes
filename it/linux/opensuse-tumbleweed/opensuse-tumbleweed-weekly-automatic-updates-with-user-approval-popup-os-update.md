# openSUSE Tumbleweed: Weekly Automatic Updates With User Approval (Popup + os-update)

## Goal

Configure openSUSE Tumbleweed so that:

* A **weekly desktop popup** asks you to approve updates.
* If you approve, you **authenticate** (polkit prompt) and the system runs **`os-update`** (which runs `zypper dup` on Tumbleweed).
* If you decline, **nothing** runs.
* The update run is **gated** by an “approval token” so it cannot run unattended.
* Updates follow a **conservative policy**: **no automatic service restarts**, **no reboots**, and **no soft-reboots**.

This design uses:

* **System-level** `os-update.service` overridden to run through an approval gate.
* **User-level** systemd timer/service that shows the popup weekly.
* **Polkit (`pkexec`)** for safe privilege escalation when approving.

---

## Prerequisites

* A graphical desktop session (KDE/GNOME/etc.) for popup display.
* `systemd --user` is available (default on openSUSE desktops).

---

## 1) Install packages

```bash
sudo zypper refresh
sudo zypper install -y os-update libnotify-tools polkit
sudo zypper install -y kdialog zenity
```

Notes:

* `kdialog` is preferred on KDE Plasma.
* `zenity` is preferred on GNOME and many other desktops.
* Installing both is fine.

---

## 2) Configure os-update behavior for Tumbleweed (conservative policy)

Create or update `/etc/os-update.conf`:

```bash
sudo tee /etc/os-update.conf >/dev/null <<'EOF'
# /etc/os-update.conf
#
# Conservative policy:
# - Apply updates (Tumbleweed rolling upgrade)
# - Never restart services automatically
# - Never trigger reboot or soft-reboot automatically
# - You decide when to restart services / reboot

# Tumbleweed rolling updates:
UPDATE_CMD="dup"

# Do not auto-reboot; keep reboot decision manual.
# ("none" prints/logs that a reboot is required, but does not trigger one.)
REBOOT_CMD="none"

# Do not restart services automatically after updating.
RESTART_SERVICES="no"

# Optional safety list (only relevant if RESTART_SERVICES is later set to "yes"):
# Keep defaults (dbus/dbus-broker) and add display-manager to avoid GUI logout.
IGNORE_SERVICES_FROM_RESTART="dbus dbus-broker display-manager"

# Do not allow os-update to trigger a soft-reboot.
SERVICES_TRIGGERING_SOFT_REBOOT=""

# Do not allow os-update to decide that certain services force a full reboot.
SERVICES_TRIGGERING_REBOOT=""

# Optional: log tag (leave as default if you prefer)
# LOG_TAG="root"

# Optional: ignore specific services completely (rarely needed)
# IGNORE_SERVICES=""
EOF
```

Verify:

```bash
sudo cat /etc/os-update.conf
```

Why these keys matter:

* `UPDATE_CMD="dup"` makes `os-update` perform the rolling upgrade behavior appropriate for Tumbleweed. ([openSUSE Manpages][1])
* `REBOOT_CMD="none"` ensures `os-update` **does not trigger a reboot** (it will only log/print that a reboot is required). ([openSUSE Manpages][1])
* `RESTART_SERVICES="no"` disables `os-update`’s automatic “restart services that still use old libraries” behavior. ([openSUSE Manpages][1])
* `SERVICES_TRIGGERING_SOFT_REBOOT=""` prevents `os-update` from choosing a **systemd soft-reboot**, which restarts userspace and can terminate a running desktop session. ([openSUSE Manpages][1])

Practical note: The manpage documents `/etc/os-update.conf` as an override file (typically you only set variables you want to change versus vendor defaults). Keeping the full conservative profile in one file is still operationally fine; just be aware you’re explicitly pinning behavior even if defaults change later. ([openSUSE Manpages][1])

---

## 3) Add an approval gate for os-update (system level)

### 3.1 Create the gated wrapper

This wrapper runs `os-update` only if an approval token exists and is recent. It consumes the token (one-shot approval) and logs decisions.

```bash
sudo tee /usr/local/sbin/os-update-approved >/dev/null <<'EOF'
#!/bin/sh
set -eu

APPROVAL_FILE="/etc/os-update.approved"
MAX_AGE_DAYS=7

# Locate os-update executable robustly
if [ -x /usr/libexec/os-update ]; then
  OS_UPDATE="/usr/libexec/os-update"
elif [ -x /usr/sbin/os-update ]; then
  OS_UPDATE="/usr/sbin/os-update"
else
  OS_UPDATE="$(command -v os-update || true)"
fi

if [ -z "${OS_UPDATE:-}" ] || [ ! -x "${OS_UPDATE:-/nonexistent}" ]; then
  logger -t os-update "ERROR: cannot find executable os-update"
  exit 1
fi

if [ ! -e "$APPROVAL_FILE" ]; then
  logger -t os-update "Skipped: no approval file ($APPROVAL_FILE)"
  exit 0
fi

# Require the approval to be recent
if ! find "$APPROVAL_FILE" -maxdepth 0 -mtime "-$MAX_AGE_DAYS" -print -quit | grep -q . ; then
  logger -t os-update "Skipped: approval file older than ${MAX_AGE_DAYS} days ($APPROVAL_FILE)"
  exit 0
fi

# One-shot approval: consume the token before running
rm -f "$APPROVAL_FILE"

exec "$OS_UPDATE"
EOF

sudo chmod 0755 /usr/local/sbin/os-update-approved
```

### 3.2 Override the system `os-update.service` to use the wrapper

```bash
sudo systemctl edit os-update.service
```

Paste:

```ini
[Service]
ExecStart=
ExecStart=/usr/local/sbin/os-update-approved
```

Apply:

```bash
sudo systemctl daemon-reload
```

---

## 4) Create a privileged helper invoked on approval (polkit)

This helper creates the token and triggers the update service.

```bash
sudo tee /usr/local/sbin/os-update-approve-and-run >/dev/null <<'EOF'
#!/bin/sh
set -eu

touch /etc/os-update.approved
chmod 0600 /etc/os-update.approved
chown root:root /etc/os-update.approved

systemctl start os-update.service
EOF

sudo chmod 0755 /usr/local/sbin/os-update-approve-and-run
```

Manual approval command (equivalent to clicking “Yes” in the popup):

```bash
pkexec /usr/local/sbin/os-update-approve-and-run
```

Fallback without pkexec:

```bash
sudo /usr/local/sbin/os-update-approve-and-run
```

---

## 5) Create the desktop popup script (user level)

This script shows a dialog and, if approved, calls `pkexec` to run the helper.

```bash
mkdir -p ~/.local/bin

tee ~/.local/bin/os-update-approval-popup >/dev/null <<'EOF'
#!/bin/sh
set -eu

TITLE="System Updates Approval"
MSG="Weekly updates are ready.

Approve to run the update now (os-update / zypper dup). You will be asked to authenticate.

If you prefer doing it manually later, run:
  pkexec /usr/local/sbin/os-update-approve-and-run
(or: sudo /usr/local/sbin/os-update-approve-and-run)

Logs:
  journalctl -u os-update.service -n 200 --no-pager
"

# Always send a notification as a fallback
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "Weekly updates require approval. Run: pkexec /usr/local/sbin/os-update-approve-and-run"
fi

approve() {
  if command -v pkexec >/dev/null 2>&1; then
    pkexec /usr/local/sbin/os-update-approve-and-run
  else
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "$TITLE" "pkexec not found. Run: sudo /usr/local/sbin/os-update-approve-and-run"
    fi
    exit 1
  fi
}

# Prefer KDE dialog, then Zenity, else notification-only
if command -v kdialog >/dev/null 2>&1; then
  if kdialog --title "$TITLE" --yesno "$MSG"; then
    approve
  fi
elif command -v zenity >/dev/null 2>&1; then
  if zenity --question --title="$TITLE" --text="$MSG"; then
    approve
  fi
else
  # No dialog tool; rely on notification only
  exit 0
fi
EOF

chmod 0755 ~/.local/bin/os-update-approval-popup
```

---

## 6) Schedule the popup weekly (systemd user timer)

Create the user units:

```bash
mkdir -p ~/.config/systemd/user
```

### 6.1 Service unit

```bash
tee ~/.config/systemd/user/os-update-approval-popup.service >/dev/null <<'EOF'
[Unit]
Description=Popup asking approval to run os-update

[Service]
Type=oneshot
ExecStart=%h/.local/bin/os-update-approval-popup
EOF
```

### 6.2 Timer unit (weekly schedule)

Example: Every **Monday at 09:00**.

```bash
tee ~/.config/systemd/user/os-update-approval-popup.timer >/dev/null <<'EOF'
[Unit]
Description=Weekly timer for os-update approval popup

[Timer]
OnCalendar=Mon *-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

Enable:

```bash
systemctl --user daemon-reload
systemctl --user enable --now os-update-approval-popup.timer
```

Verify next run:

```bash
systemctl --user list-timers --all | grep os-update-approval-popup
```

---

## 7) Prevent unattended updates (recommended)

Disable the vendor timer so updates only run when you approve:

```bash
sudo systemctl disable --now os-update.timer
```

You keep `os-update.service` available; it will be started by the approval helper.

---

## 8) Test immediately

Trigger the popup now:

```bash
systemctl --user start os-update-approval-popup.service
```

If you click **Yes** and authenticate, the update should run.

View logs:

```bash
sudo journalctl -u os-update.service -n 200 --no-pager
```

---

## 9) How to monitor updates (current and past runs)

### 9.1 Check if it is running right now

```bash
sudo systemctl status os-update.service --no-pager
sudo systemctl show os-update.service -p ActiveState,SubState,ExecMainPID,ExecMainStatus,Result
ps aux | egrep 'os-update|zypper|transactional-update' | grep -v egrep
```

Note: `os-update.service` is typically `oneshot`, so it returns to `inactive` after completion—use logs for outcomes.

### 9.2 Follow live output while it runs

```bash
sudo journalctl -u os-update.service -f
```

### 9.3 Review last run output

```bash
sudo journalctl -u os-update.service -n 200 --no-pager --output=short-iso
sudo systemctl show os-update.service -p Result,ExecMainStatus,ExecMainCode
```

### 9.4 Review history (last 30 days)

```bash
sudo journalctl -u os-update.service --since "30 days ago" --no-pager --output=short-iso
sudo journalctl -u os-update.service --since "30 days ago" --no-pager | egrep -i 'Started|Finished|Skipped|ERROR'
```

### 9.5 Confirm what actually updated (zypper/zypp logs)

```bash
sudo tail -n 200 /var/log/zypp/history
sudo tail -n 200 /var/log/zypper.log
rpm -qa --last | head -n 30
```

### 9.6 Confirm token was consumed (optional)

After a successful approved run, the token should be removed:

```bash
sudo ls -l /etc/os-update.approved
```

---

## 10) Daily usage / workflow

### When the popup appears

* Click **Yes** → authenticate → update runs immediately.
* Click **No** → nothing runs.

### Approve later manually

```bash
pkexec /usr/local/sbin/os-update-approve-and-run
```

(or)

```bash
sudo /usr/local/sbin/os-update-approve-and-run
```

### Revoke approval (if you created a token manually)

```bash
sudo rm -f /etc/os-update.approved
```

---

## 11) Proof commands (for compliance screenshots)

```bash
systemctl --user status os-update-approval-popup.timer --no-pager
systemctl --user list-timers --all | grep os-update-approval-popup

systemctl cat os-update.service
ls -l /usr/local/sbin/os-update-approved /usr/local/sbin/os-update-approve-and-run

sudo cat /etc/os-update.conf
sudo journalctl -u os-update.service --since "30 days ago" --no-pager
```

---

## Appendix: Change the weekly schedule

Edit the timer:

```bash
nano ~/.config/systemd/user/os-update-approval-popup.timer
```

Change `OnCalendar=...` (examples):

* Every Sunday at 18:00:

  * `OnCalendar=Sun *-*-* 18:00:00`
* Every weekday at 09:00:

  * `OnCalendar=Mon..Fri *-*-* 09:00:00`

Reload:

```bash
systemctl --user daemon-reload
systemctl --user restart os-update-approval-popup.timer
systemctl --user list-timers --all | grep os-update-approval-popup
```

---

[1]: https://manpages.opensuse.org/os-update "os-update(8) — os-update"
