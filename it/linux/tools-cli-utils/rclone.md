# rclone

Initialize and configure your Google Drive remote with:

```bash
rclone config
```

## google drive example

- https://rclone.org/drive/#making-your-own-client-id

Follow the interactive prompts to create a new “remote” (e.g., `mygdrive`), choose **Google Drive**, and complete the OAuth flow in your browser .

Create a mount point and start the FUSE mount:

```bash
mkdir -p ~/gdrive

# Before mounting, confirm that rclone can see your Drive contents:
rclone ls mygdrive:

rclone mount mygdrive: ~/gdrive --daemon

## to interrupt / unmount
fusermount -u ~/gdrive
```

This makes your Drive available under `~/gdrive`. You can then browse and manipulate files as though they were local .

#### VFS Caching

For improved compatibility (especially with editors, IDEs, and media software), enable full VFS caching:

```bash
rclone mount mygdrive: ~/gdrive --daemon \
  --vfs-cache-mode full

rclone mount mygdrive: ~/gdrive -vv --daemon --filter-from=.rcloneignore \
  --vfs-cache-mode full
```

This caches file data locally and makes operations like reads, writes, and renames behave more like a native filesystem .

### 4. Automating with systemd

To ensure your Drive auto-mounts at boot, create a systemd service unit `/etc/systemd/system/rclone-gdrive.service`:

```ini
[Unit]
Description=Mount Google Drive (rclone)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount mygdrive: /home/youruser/gdrive \
  --config /home/youruser/.config/rclone/rclone.conf \
  --vfs-cache-mode full
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start it with:

```bash
sudo systemctl enable rclone-gdrive
sudo systemctl start rclone-gdrive
```

## Nextcloud

- Nextcloud External Storage - mounting external services with Rclone? https://forum.cloudron.io/topic/3463/nextcloud-external-storage-mounting-external-services-with-rclone/12
  - this article explains all
  - hard to make it work
  - inconsistent
  - when able to make it work: it's slow
- What are people's thoughts on using s3fs in production? https://www.reddit.com/r/aws/comments/a5jdth/what_are_peoples_thoughts_on_using_s3fs_in/
  - https://www.reddit.com/r/aws/comments/dplfoa/why_is_s3fs_such_a_bad_idea/

## Ignore files

While rclone doesn't natively support `.gitignore`-style exclusion files, you can achieve similar functionality by creating a filter file at the root of your directory and referencing it in your rclone command.

### 📄 Step 1: Create a Filter File

In the root directory of your project, create a file named `.rcloneignore` (or any name you prefer). This file will contain your exclusion patterns.

**Example `.rcloneignore` content:**

```plaintext
# Exclude node_modules directories
- /node_modules/**

# Exclude all .log files
- *.log

# Exclude temporary files
- *.tmp

# Include all other files
+ *
```

In this file:

* Lines starting with `-` specify patterns to exclude.
* Lines starting with `+` specify patterns to include.
* The `+ *` line at the end ensures that all other files are included.([techwiki.co.uk][1])

### 🚀 Step 2: Use the Filter File in Your rclone Command

When running your rclone command, use the `--filter-from` flag to reference your filter file. For example:

```bash
rclone sync /path/to/source remote:destination --filter-from=.rcloneignore
```

Replace `/path/to/source` with the path to your local directory and `remote:destination` with your rclone remote and desired destination path.

### 🧪 Step 3: Test Your Filter Rules

Before performing the actual sync, it's a good idea to test your filter rules to ensure they work as expected. You can use the `--dry-run` flag to simulate the sync operation:

```bash
rclone sync /path/to/source remote:destination --filter-from=.rcloneignore --dry-run
```

This command will show you which files would be synced without actually transferring any data.([GitHub][2])

### 🔍 Additional Tips

* **Pattern Matching:** rclone uses a pattern matching system similar to shell globbing. For more complex patterns, refer to the [rclone filtering documentation](https://rclone.org/filtering/).

* **Excluding Directories Based on File Presence:** If you want to exclude directories that contain a specific file (e.g., `.ignore`), you can use the `--exclude-if-present` flag:

```bash
  rclone sync /path/to/source remote:destination --exclude-if-present .ignore
```

This will exclude any directory that contains a file named `.ignore`.

* **Avoid Mixing Filter Flags:** It's recommended to avoid mixing `--include`, `--exclude`, and `--filter` flags in the same command, as this can lead to unexpected behavior. Instead, consolidate your rules into a single filter file and use the `--filter-from` flag.

By following these steps, you can effectively manage file and directory exclusions in rclone, similar to how `.gitignore` works in Git.

[1]: https://techwiki.co.uk/RClone_-_Filtering?utm_source=chatgpt.com "RClone - Filtering - Tech Wiki"
[2]: https://github.com/rclone/rclone/issues/394?utm_source=chatgpt.com "Exclude directories? · Issue #394 · rclone/rclone - GitHub"
