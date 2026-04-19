# Security

> Main doc for security related topic

<!--toc-->


## General

How to generate a secure password?

For example you can generate a 128 character password (must all be on one line) with:[^1]

```sh
openssl rand -base64 128 | tr -d '\n' > /etc/restic/pw.txt
```


## References

[^1]: https://github.com/erikw/restic-automatic-backup-scheduler "github erikw / restic-automatic-backup-scheduler"
