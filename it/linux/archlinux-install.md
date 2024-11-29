# Archlinux Install


## LUKS on a partition

> https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition

```
+-----------------------+------------------------+-----------------------+
| Boot partition        | LUKS encrypted root    | Optional free space   |
|                       | partition              | for additional        |
|                       |                        | partitions to be set  |
| /boot                 | /                      | up later              |
|                       |                        |                       |
|                       | /dev/mapper/root       |                       |
|                       |------------------------|                       |
| /dev/sda1             | /dev/sda2              |                       |
+-----------------------+------------------------+-----------------------+
```

### Drive preparation

> https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation

- Secure erasure of the drive (if necessary)
- Partitioning
  1. `/boot`
  2. `/`

