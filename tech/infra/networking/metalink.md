# What is Metalink?

- **Definition and Purpose:**
  Metalink is an open standard (an XML-based format) used to describe downloadable files along with detailed metadata. This metadata includes:
  - **Mirror URLs:** A list of alternative download sources (mirrors) that host the same file.
  - **Checksums/Hashes:** Cryptographic hashes (such as MD5, SHA-1, and SHA-256) to verify the integrity of the downloaded file.
  - **P2P Links and Torrents (optional):** In some cases, Metalink files can also include Peer-to-Peer (P2P) links, such as BitTorrent, to further enhance download efficiency.

  By having all this information bundled together, download managers can:
  - **Automatically choose the fastest or most reliable mirror** based on your location.
  - **Perform segmented downloading:** Download different parts of the file simultaneously from several mirrors, which can boost download speeds.
  - **Resume or repair downloads:** If parts of the file are corrupted or a connection drops, the client can try alternative sources or only re-download the affected segments.

- **Usage in openSUSE Downloads:**
  openSUSE offers Metalink files (with extensions like `.meta4` or `.metalink`) for its ISO images. If you choose the Metalink option, your download manager (for example, [aria2](https://aria2.github.io/) or the Firefox extension DownThemAll!) can automatically parse this file to fetch the ISO from multiple sources, verify integrity via included checksums, and even resume downloads if there’s an interruption.

- **Benefits:**
  - **Reliability:** If one mirror is down or slow, others can take over seamlessly.
  - **Speed:** Multiple sources can be used concurrently to download separate parts of the file, potentially resulting in higher speeds than a single server download.
  - **Error Correction:** In cases where a segment of the file is missing or corrupted, the manager can download just that portion, saving time and bandwidth.

For example, if you’re using a command-line download manager like aria2, you might run a command similar to:

```bash
aria2c https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso.meta4
```

This command instructs aria2 to download the Metalink file, which it then uses to download the Tumbleweed ISO from multiple mirrors while verifying the file’s integrity automatically.

---

### References

- Information on Metalink as used by openSUSE can be found in the openSUSE Wiki article on [Metalink](https://en.opensuse.org/Metalink) citeturn0search3.
- Details on openSUSE Tumbleweed download options are available at the official [openSUSE Tumbleweed download page](https://get.opensuse.org/tumbleweed/) citeturn0search2.

By using Metalink, openSUSE provides a robust and efficient download mechanism, especially useful when downloading large files like ISO images over varying network conditions.
