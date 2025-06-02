# Nextcloud
> filesync

[toc]

# General


# S3 Storage
> Nextcloud / Cloudron / External Storage Bucket S3

!! BAD IDEA

[Any experiences using S3 as primary storage?](https://www.reddit.com/r/NextCloud/comments/ly99em/any_experiences_using_s3_as_primary_storage/)

# Alternatives

- https://filerun.com/
- [seafile](./seafile.md)

## Hetzner Storage Share Nextcloud

- backups are not part of the capacity of your Storage Box.

"Services" -> "OCC". You can then execute these commands:

- Trash bin contents:
  ```
  trashbin:cleanup --all-users
  ```

- File versions:
  ```
  versions:cleanup %USER%
  ```

- You can show the users with the following OCC command:
  ```
  user:list
  ```
