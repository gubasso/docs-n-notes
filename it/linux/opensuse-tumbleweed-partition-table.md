# Opensuse Tumbleweed Partition Table

When setting up a new installation of openSUSE Tumbleweed, it's important to choose a partition scheme that suits your needs, especially given Tumbleweed's rolling release nature which requires frequent updates. Here are some recommended partitioning guidelines:

1. **Partition Table Type**: 
   - Use GPT (GUID Partition Table) if your system supports UEFI. GPT allows for more partitions and is generally more robust than MBR[3].

2. **/boot/efi Partition**:
   - Size: 500 MB
   - File System: FAT32
   - This partition is necessary for UEFI systems and should be mounted at `/boot/efi`[6].
   - partition ID: EFI System Partition

3. **Root (/) Partition**:
   - Size: At least 50 GB if using Btrfs, which is the default for openSUSE. This is because Btrfs snapshots can consume significant space, especially with frequent updates[2][5].
   - role: Operating System
   - partition id: Linux / `8300` (Linux filesystem) for the root partition.
   - File System: Btrfs is recommended for its snapshot capabilities, which can be useful for rollback after updates.

4. **Swap Partition**:
   - Size: Typically equal to the amount of RAM if you plan to use hibernation, otherwise 2-4 GB should suffice[2][6].
   - If you have 16 GB of RAM and do not plan to hibernate, a 2-4 GB swap partition is adequate[6].

5. **/home Partition**:
   - Consider creating a separate partition for `/home` if you plan to store personal data separately. Otherwise, it can be a subvolume within the Btrfs root partition.
   - Size: Allocate the remaining space after setting up other partitions. If you store most data elsewhere, a smaller `/home` partition is acceptable[2][6].
   - File System: Btrfs is suitable, but you may also use ext4 or XFS if preferred[6].

6. **Additional Partitions**:
   - If you plan to use virtual machines or have specific storage needs, consider creating additional partitions. For example, a separate partition for virtual machines could be formatted with XFS or ext4[6].

These suggestions provide a flexible and efficient setup for openSUSE Tumbleweed, balancing the need for system updates, user data storage, and system recovery options. Adjust the sizes based on your specific usage and storage capacity.

Citations:
[1] https://www.youtube.com/watch?v=HWi-W_P4FjY
[2] https://forums.opensuse.org/t/recommended-partition-scheme-for-90-gb-of-free-disk-space/134597
[3] https://en.opensuse.org/SDB:Partitioning
[4] https://forums.opensuse.org/t/partition-information-for-tumbleweed-installation/125454
[5] https://forums.opensuse.org/t/partitioning-at-installation-upgrade/141077
[6] https://www.reddit.com/r/openSUSE/comments/e7gn6o/recommended_partition_table_for_tumbleweed_install/
