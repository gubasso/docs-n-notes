# Personal Security Framework

A concise guide to establishing strong, consistent practices for your personal infrastructure. Think of this as the “starter kit” for your own security operations.

---

<!-- toc -->

- [Secure Email Account](#secure-email-account)
- [Essential Tools](#essential-tools)
  - [Code Editor](#code-editor)
  - [Local Password Vault](#local-password-vault)
- [Public Dotfiles](#public-dotfiles)
- [Gopass (Command-Line Vault)](#gopass-command-line-vault)
- [Private Cloud Directory](#private-cloud-directory)
- [Private Dotfiles](#private-dotfiles)
  - [What to Store](#what-to-store)
  - [Deployment Methods](#deployment-methods)
  - [Example Structure](#example-structure)
  - [Best Practices & Tips](#best-practices--tips)
- [Private and Secret Dotfiles](#private-and-secret-dotfiles)
  - [Prerequisites](#prerequisites)
  - [Directory Setup](#directory-setup)
  - [Example File Tree](#example-file-tree)
  - [Saving Your Encryption Passphrase](#saving-your-encryption-passphrase)
  - [Mounting Script](#mounting-script)

<!-- tocstop -->

---

## Secure Email Account

**Objective:** Use a dedicated, privacy-focused email address (with 2FA) for all critical services.

* **Example:**
  `timtones@proton.me`

* **Key Features to Enable:**
  * Two-Factor Authentication (2FA) – ideally hardware token (WebAuthn/U2F)
  * Strong, unique recovery codes stored offline

* **Use Cases:**
  * Infrastructure provisioning (cloud consoles, DNS providers)
  * Server access (SSH key recovery, alerts)
  * Online vaults and password managers
  * Cloud storage / Nextcloud accounts
  * Domain name registrar logins

> 💡 **Tip:** Wherever possible, use a hardware security key (e.g. YubiKey) for the second factor instead of SMS or TOTP to defend against phishing.

---

## Essential Tools

### Code Editor

* **Recommendation:** Switch from VS Code to **VSCodium**
  * Fully open-source, no telemetry
  * Compatible extensions ecosystem

* **Configuration Tips:**
  * Disable unneeded telemetry and automatic crash reports
  * Install security linters (e.g. ESLint for JavaScript, Bandit for Python)

### Local Password Vault

* **KeepassXC**
  * File example: `timtones.kbdx`
  * **Best Practices:**
    * Use a strong master password (passphrase ≥ 20 characters)
    * Enable key-file + master password combination
    * Regularly backup vault to encrypted media

> 🔒 **Tip:** Automate periodic exports and verify vault integrity with
>
> ```bash
> keepassxc-cli check-integrity timtones.kbdx
> ```

---

## Public Dotfiles

Maintain a public repository for your non-secret configuration and scripts:

```bash
git clone https://github.com/gubasso/dotfiles.git
```

* **Why:**
  * Showcases best practices
  * Enables easy setup on new machines

* **Security Additions:**
  * Use [git-secrets](https://github.com/awslabs/git-secrets) to scan for accidental commits of private keys
  * And/or: pre-commit hooks to security checks
  * Keep all secret templates out of the repo (e.g. `config.example` only)

> 📚 **Tip:** Include a `CONTRIBUTING.md` explaining how others can securely contribute (GPG-signed commits, branch protection).

---

## Gopass (Command-Line Vault)

Gopass is a modern, git-backed password manager for the CLI.

* **Setup Guide:**
  [https://github.com/gubasso/docs-n-notes/blob/master/it/pass-gopass/gopass.md](https://github.com/gubasso/docs-n-notes/blob/master/it/pass-gopass/gopass.md)

* **Storage:**
  * Host the git remote in a **private** GitLab repository
  * Encrypt all git communication via SSH and hardware-key agent

* **Usage Tips:**
  * Organize entries by domain (`github.com`, `aws/production`, etc.)
  * Use `gopass audit` to find weak or reused passwords
  * Integrate with editor plugins (e.g. VS Code Gopass extension)
  * Prioritize safer text editors like Vim/Neovim and Nano

---

## Private Cloud Directory

Define a single point of reference for your personal files in the cloud, e.g.:

```bash
export CLOUD_DIR="$HOME/Nextcloud"
```

Define a place to save and backup (sync with cloud) your private files, e.g.:

```bash
export PRIVATE_DIR="$CLOUD_DIR/Private"
```

* **Storage Providers:** Dropbox, Nextcloud, etc.
* **Access Control:**
  ```bash
  chmod 700 "$PRIVATE_DIR"
  ```

* **Backup Strategy:**
  * Use `restic` to back up encrypted snapshots to an offsite location

---

## Private Dotfiles

Maintain a **private** repository for configuration files you don’t want exposed publicly—but which aren’t highly sensitive. Store it alongside your other cloud-synced data:

```bash
mkdir -p "$PRIVATE_DIR/.dotfiles-private"
cd "$PRIVATE_DIR/.dotfiles-private"
```

### What to Store

* Personal application settings (editor snippets, window layouts)
* Custom desktop entries, shell aliases, etc.
* Non-secret but machine-specific configs (theme files, UI tweaks)

> 🔐 **Note:** Because these files aren’t secrets, you can keep them unencrypted in your cloud service. Still, treat the repo like private data.

### Deployment Methods

* **GNU Stow** (preferred)
  1. Organize each app or service in its own directory under `.dotfiles-private/`
  2. From inside `.dotfiles-private/`, run:
     ```bash
     stow brave kde suse-shell thunderbird
     ```
     This creates symlinks in your home directory.

* **Manual Copy**
  ```bash
  cp -r "$PRIVATE_DIR/.dotfiles-private/kde/.local/share/applications/" \
        ~/.local/share/applications/
  ```

### Example Structure

```
.dotfiles-private/
├── brave.md              # Notes or tweaks for Brave browser
├── kde
│   └── .local
│       └── share
│           └── applications
│               ├── brave-browser-tumblesuse.desktop
│               ├── brave-browser-valinor.desktop
│               ├── mimeapps.list
│               └── webapp-google.desktop
├── suse-shell
│   └── .config
│       └── shell_alias_cwnt     # Custom CWNT shell aliases
└── thunderbird
    └── signatures
        ├── gubasso@cwnt
        └── gubasso@cwnt-min
```

### Best Practices & Tips

* **One Directory per Component:** Keep each application or tool in its own folder (`kde/`, `brave/`, etc.) for clarity.
* **README and Documentation:** Add a `README.md` at the repo root explaining layout, usage of `stow`, and any dependencies.
* **Host-Specific Overrides:** Use subfolders (e.g. `kde/tumblesuse/` vs. `kde/valinor/`) to manage different machines or OS versions.
* **Automate on Login:** Add a small script in your shell startup (`~/.bashrc` or `~/.profile`) to pull and re-stow after each boot:

  ```bash
  (cd "$PRIVATE_DIR/.dotfiles-private" && stow --restow *)
  ```

Thought for a couple of seconds


---

## Private and Secret Dotfiles

Store highly sensitive configuration files in an **encrypted** directory, synced to your cloud but only saved in its ciphered form. We’ll use **gocryptfs** as the encryption layer.

### Prerequisites

1. Install gocryptfs
2. Read the detailed guide:
   [https://github.com/gubasso/docs-n-notes/blob/master/it/gocryptfs.md](https://github.com/gubasso/docs-n-notes/blob/master/it/gocryptfs.md)

### Directory Setup

```bash
export CLOUD_DIR="$HOME/Nextcloud"
export PRIVATE_DIR="$CLOUD_DIR/Private"

# Local decrypted mount point
mkdir -p ~/.dotfiles-secret

# Encrypted data will live here (in your cloud sync folder)
mkdir -p "$PRIVATE_DIR/.dotfiles-secret.enc"
```

* **Encrypted directory:** `$PRIVATE_DIR/.dotfiles-secret.enc`
* **Decrypted mount point:** `~/.dotfiles-secret`

### Example File Tree

Below is a fleshed-out example of what you might store under `~/.dotfiles-secret` once it’s mounted. Each subtree illustrates common secret files and possible variants.

```
dotfiles-secret/
├── aws
│   └── .aws
│       ├── config                # Named profiles, region defaults
│       ├── credentials           # Access keys
│       └── session-token         # Temporary STS tokens (optional)
├── azure
│   └── service-principals
│       ├── dev-sp.json           # Dev environment app credentials
│       ├── prod-sp.json          # Production service principal
│       └── cert.pem              # Client certificate for auth
├── gcp
│   ├── cwnt-gce-test-auth.json   # JSON key for test GCE instance
│   ├── terraform-sa.json         # Service account for Terraform
│   └── auth-token                # CLI authentication cache (if used)
├── gpg
│   └── .gnupg
│       ├── private-keys-v1.d     # Your encrypted private subkeys
│       ├── gpg-agent.conf        # Agent settings (pinentry, sockets)
│       └── pubring.kbx           # Public keyring
├── openvpn
│   ├── client
│   │   ├── client.ovpn           # Single-file VPN profile
│   │   └── creds.txt             # Username / password file (chmod 600)
│   ├── templates
│   │   ├── tcp-region1.ovpn      # Region-specific template files
│   │   ├── udp-region2.ovpn
│   │   └── setup.sh              # Script to generate configs overlay
│   └── scripts
│       └── ln_openvpn.sh         # Symlink helper for system services
└── ssh
    ├── config                    # Main SSH config with includes
    ├── config.d
    │   ├── cwnt.conf             # Work-specific host blocks
    │   └── personal.conf         # Home and personal servers
    ├── keys
    │   ├── id_ed25519            # Default keypair
    │   ├── id_ed25519.pub
    │   ├── company_ed25519       # Company key, GPG-signed
    │   ├── company_ed25519.pub
    │   ├── aws-regionX.pem       # EC2 PEM keys (read-only perms)
    │   └── google_compute_known_hosts
    └── known_hosts               # Consolidated known_hosts file
```

> **Why this matters:**
>
> * Separates **secret** data from non-secret configs.
> * Cloud sync only sees encrypted blobs — even if your Nextcloud is compromised, your plaintext never leaves your control.

### Saving Your Encryption Passphrase

Once your encrypted directory is initialized, store the passphrase (and any mount parameters) in both of your vaults:

* **KeePassXC (GUI):** Create an entry with your gocryptfs password and mount command.
* **Gopass (CLI):**
  ```bash
  gopass insert apps/gocryptfs/dotfiles-secret
  ```

### Mounting Script

Use a small wrapper to mount (and unmount) easily:

- Script: https://github.com/gubasso/dotfiles/blob/master/bin/.local/bin/mntcrypt

```bash
#!/usr/bin/env bash
# File: ~/.local/bin/mntcrypt
# Usage: mntcrypt ENCRYPTED_DIR DECRYPTED_DIR GOPASS_ENTRY
...
...
```

**Example Invocation:**

```bash
mntcrypt "$PRIVATE_DIR/.dotfiles-secret.enc" \
         "$HOME/.dotfiles-secret" \
         "apps/gocryptfs/dotfiles-secret"
```

> 🔄 **Automation Tip:**
>
> * Add an entry to your shell startup (e.g. `~/.bash_profile`) to auto-mount on login:
>
>   ```bash
>   if ! mountpoint -q ~/.dotfiles-secret; then
>     mntcrypt "$PRIVATE_DIR/.dotfiles-secret.enc" "$HOME/.dotfiles-secret" apps/gocryptfs/dotfiles-secret
>   fi
>   ```
> * Ensure you `chmod 700 ~/.dotfiles-secret` to restrict access to your user only.
