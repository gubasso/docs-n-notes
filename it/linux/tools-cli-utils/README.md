# CLI Tools

- axel
  - https://github.com/axel-download-accelerator/axel
  - wget alternative, curl alternative, download in parallel
  - cli download cli
  ```sh
  axel -n 10 http://example.com/file.zip
  ```

- aria2: download metalink .meta4
  - [[what-is-metalink]]


Basic Usage of aria2

- **Downloading a File Directly:**

  To download a file from a single URL, simply run:

  ```bash
  aria2c http://example.com/path/to/file.iso
  ```

- **Downloading with Multiple Connections (Segmented Downloading):**

  aria2 supports segmented downloading by default. You can also specify options to fine-tune the performance. For example:

  ```bash
  aria2c -x 16 -s 16 -k 1M http://example.com/path/to/file.iso
  ```

  - `-x 16` sets the maximum number of connections per server.
  - `-s 16` splits the download into 16 segments.
  - `-k 1M` sets the segment size to 1 Megabyte.

- **Downloading Using a Metalink File:**

  If you have a Metalink file (with an extension like `.meta4` or `.metalink`), aria2 can process it automatically. For example:

  ```bash
  aria2c https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso.meta4
  ```

  In this case, aria2 reads the Metalink file to retrieve multiple download sources (mirrors), verify file integrity using checksums, and even resume downloads if necessary.
