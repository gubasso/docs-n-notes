# GPG

## gpg-agent

Config:

**`~/.gnupg/gpg-agent.conf`**
```
# cache password really long time
max-cache-ttl 60480000
default-cache-ttl 60480000
```

Reload the agent:

```sh
gpg-connect-agent reloadagent /bye
```


## Unorganized

- GPG: [Armored ASCII vs. Binary GPG Files - Linux Journal](https://www.linuxjournal.com/files/linuxjournal.com/linuxjournal/articles/048/4892/4892s2.html)
"Armored ASCII (whose filename suffix is .asc) is the most portable data format gpg uses, in contrast to gpg's default binary format (which uses the filename suffix .gpg). Unlike this binary format, Armored ASCII can be copied and pasted, into e-mail for example. If saved to disk, an Armored ASCII file is identical to a normal text file. For this reason you'll probably wish to use Armored ASCII most of the time when exporting, backing up and transmitting keys."

- How to use symmetric (password) encryption with GPG
``` [^ops12][^ops13]
# Encrypt
gpg -c -a --cipher-algo AES256 my_file.txt
# Decrypt
gpg -a --output decrypted_file.txt --decrypt my_file.txt.asc
```

## GPG Create Identity, Keys, Encrypt/Decrypt

### **How to encrypt large files secure way (the best method I've found)**
> Tutorial: Encrypt, Decrypt, Sign a file with GPG Public Key in Linux

Steps:
1. Creating a GPG Key Pair
2. List the key pair and fingerprint
3. Exporting and Importing Public Keys
4. Signing a Public Key
5. **Encrypting and Decrypting a File**

Encrypt file:
```
# recipient@email.com is the id of recipient whose public key you've added to your keyring (step 4)
gpg --recipient recipient@email.com --encrypt secret_file
```

To see this encrypted file:
```
file secret_file.gpg
```

Decrypt file:
```
gpg --output secret_file_decrypted --decrypt secret_file.gpg
```

Other topics:
- Deleting public keys from keyring


### **Generating a Revocation Certificate**

If your private key becomes known to others, you will need to disassociate the old keys from your identity, so that you can generate new ones. To do this, you will require a revocation certificate. We’ll do this now and store it somewhere safe.

### **Backup and restore GPG Keys**

- https://serverfault.com/questions/86048/how-to-backup-gpg

**export / backup**

```sh
gpg --export --armor your@id.here > your@id.here.pub.asc
gpg --export-secret-keys --armor your@id.here > your@id.here.priv.asc
gpg --export-secret-subkeys --armor your@id.here > your@id.here.sub_priv.asc
gpg --export-ownertrust > ownertrust.txt
```

**import / restore**

```sh
gpg --import your@id.here.pub.asc
gpg --import your@id.here.priv.asc
gpg --import your@id.here.sub_priv.asc
gpg --import-ownertrust ownertrust.txt
```
