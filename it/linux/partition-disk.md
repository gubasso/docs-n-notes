# Partition Disk

[Tip: Check that your NVMe drives and Advanced Format hard disk drives are using the optimal logical sector size before partitioning.][^2]

## Example layout: UEFI/GPT - Full Disk Encryption (LVM on Luks)

```
Device      Size        Type
/dev/sda1   1GB         EFI System
/dev/sda2  <remainder>  Linux filesystem
```

- `/dev/sda1    2048    264191    262144  1GB EFI System`
  - `/boot/efi` (Void) - `/boot` (Arch)
  - type: `EFI System`
  - filesystem: `vfat`
  - Size: 1 GB[^3]
  - Partition type GUID: `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`
  - Code: `EF00`

- `/dev/sda2  264192 100663262 100399071 96GB Linux filesystem`
  - encrypted partition
  - Size: remainder of disk
  - filesystem: XFS? (ext4?)
  - type: `Linux Filesystem`
  - code: `8300`

- In `/dev/sda2`, encrypted
  - Volume: (swap)
    - Size: 1,5x RAM[^1]
    - For 64GB RAM -> 96GB swap
  - Volume: `/` (root)
    - Size: remainder


## Full Disk Encryption: : UEFI/GPT - LVM on Luks[^4]

In this example:

- `/dev/sda1`: taken up by the EFI Partition
- `/dev/sda2`: encrypted volume

```
Device      Size        Type
/dev/sda1   1GB         EFI System
/dev/sda2  <remainder>  Linux filesystem
```


- Example[^5]:

```
+-----------------------------------------------------------------------+ +-----------------+
| Logical volume 1      | Logical volume 2      | Logical volume 3      | | Boot partition  |
|                       |                       |                       | |                 |
| [SWAP]                | /                     | /home                 | | /boot     (arch)|
|                       |                       |                       | | /boot/efi (void)|
| /dev/MyVolGroup/swap  | /dev/MyVolGroup/root  | /dev/MyVolGroup/home  | |                 |
|_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _| | (may be on      |
|                                                                       | | other device)   |
|                         LUKS encrypted partition                      | |                 |
|                           /dev/sda1                                   | | /dev/sdb1       |
+-----------------------------------------------------------------------+ +-----------------+
```

### Encrypted Volume Configuration

- For Void Linux: [Encrypted volume configuration](https://docs.voidlinux.org/installation/guides/fde.html#encrypted-volume-configuration)

- For Arch Linux[^5]


---

[^1]: https://docs.voidlinux.org/installation/live-images/partitions.html
[^2]: ../checking-disk-advanced-formats-hd-ssd-nvme.md
[^3]: https://wiki.archlinux.org/title/EFI_system_partition#Create_the_partition
[^4]: https://docs.voidlinux.org/installation/guides/fde.html
[^5]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
