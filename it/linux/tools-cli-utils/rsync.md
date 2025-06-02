# rsync

## general

- rsync vs scp: rsync is "better"[^cli1]
  - `scp` example:
    - `scp -r my/directory username@landchad.net:~/`
- rsync needs to be installed on both local and remote machines
- rsync for large files: "use rsync with the -P option. If the transfer is interrupted, you can resume it where it stopped by reissuing the command."[^cli1]
- rsync basic usage
    - rsync must be installed on both the source and the destination machine.

## examples

```
rsync -vurzP SOURCE/ DESTINATION/
rsync source host:destination
rsync host:source destination
```


Example of rsync being used to push/syncing files to server, with watchexec:

```
watchexec 'rsync -vurzP --delete-after ./* user@host:/full/path/'
watchexec 'rsync -vurzP --delete-after ./* user@host:relative/path/from/user/home'
rsync -vrzP --delete-after ~/website/ user@host:/var/www/html/
```

Example simple file copy

```
rsync -vurP SOURCE/ DESTINATION/
rsync -vurzP yourkey.pub git@yourserver.tld:˜/yourname.pub
```

Example different ssh port:
```
rsync -a -e "ssh -p 2322" /opt/media/ remote_user@remote_host_or_ip:/opt/media/
```

Specifying an ssh key:

```sh
rsync -e "ssh -i ~/.ssh/<my-private-key>"
```

```sh
# Sync all changes, deletions, and permissions:
rsync -av --delete source/ dest/

# Copy only new/modified files without deleting:
rsync -au source/ dest/

# Skip files that already exist on the receiver:
rsync -av --ignore-existing source/ dest/
```

## flags

- `-r`: recursive, dirs and subdirs

- `-v` or `-verbose`

- `-z` or `-compress`: during transfer

- `-P`: same as using both `--partial --progress`

- `-u / --update`: To updated more recently on the local filesystem. Files that don't exist are copied. Files that already exist, but have a newer timestamp are also copied.

- `--delete`: Delete files that have been deleted in the original directory
    - `--delete-after`: delete only after files are received

- `--exclude`: This option will exclude files that we specify in the parameter
    - `rsync -avhze ssh --exclude 'KEYWORD' SOURCE/ DESTINATION/`

- `--dry-run`: This option perform a trial run and will not make any changes, but gives us the same result as a real run. If the results are as expected, then we can remove the --dry-run
- `rsync --dry-run -avhze ssh --delete SOURCE/ DESTINATION/`
