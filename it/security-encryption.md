# Security / Encryption

# Related

- [SSH / Openssh](./it/security-encryption-ssh.md)

# General

- verify secret / password in git repo pre-commit precommit
  - https://github.com/Yelp/detect-secrets
  - https://github.com/sirwart/ripsecrets
  - https://github.com/gitleaks/gitleaks
  - https://github.com/trufflesecurity/trufflehog


- data at rest encryption:
    - gocryptfs <https://nuetzlich.net/gocryptfs/> / <https://mhogomchungu.github.io/sirikali/> (gui)
    - <https://wiki.archlinux.org/title/Gocryptfs>

test password strength: https://www.security.org/how-secure-is-my-password/

test ip / vpn: http://ipleak.net/

- store password in a database:
  - slow hashfunction: bcrypt, scrypt, argon2
  - not storing at all:
    - google/facebook sign in
    - email code login

# Resources

- [7 Cryptography Concepts EVERY Developer Should Know - Fireship](https://youtu.be/NuyzuNBFWxQ)
    - excelent summary of all key concepts
    - guide to "how implement password database authentication"

