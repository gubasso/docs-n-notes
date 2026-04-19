# SSH: Configuration

> config, config file

## IdentitiesOnly / `-i`

Setting `IdentitiesOnly yes` tells SSH not to use those agent-offered or default keys and to restrict itself strictly to the identity files you’ve explicitly specified (via `IdentityFile` in your config or `-i` on the command line).

This can prevent SSH from offering unwanted keys to a server, speed up authentication, and avoid hitting key-offer limits on busy agents.

- force to use one specific key[^4]:

```sh
ssh -v -p 22 -F /dev/null -o IdentitiesOnly=yes -i ~/.ssh/<private_key>
```

---

[^4]: https://superuser.com/questions/772660/howto-force-ssh-to-use-a-specific-private-key "How to force ssh to use a specific private key?"
