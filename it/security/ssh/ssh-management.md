# SSH Management

> manage keys and config securely

I will present different methods

## 1) All files inside a vault

May be keepassxc, bitwarden, etc.

Save each private key file, config file, and passwords inside the vault

- disadvantages:
  - have to manually keep everything updated by point and click

## 2) Backup automatically on Dropbox/Nextcloud

- pre-requisites
  - gocryptfs
  - gopass

Given a dir that will be used as a repository for the secret

```sh
export CLOUD_DIR="$HOME/Nextcloud"
```
