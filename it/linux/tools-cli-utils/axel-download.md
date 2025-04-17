# axel

- https://github.com/axel-download-accelerator/axel
- wget alternative, curl alternative, download in parallel
- cli download cli

```sh
axel -n 10 http://example.com/file.zip
```

```bash
axel -q -s 0 $(cat links.txt)
```

This command uses `axel` (the download accelerator) and a few flags to control its behavior, along with `$(cat links.txt)` to supply a list of URLs. Let's dissect it:

---

### 🧩 `$(cat links.txt)`

- This part **reads the file `links.txt`** and substitutes its contents (i.e., all the image URLs) directly into the command.
- So it's effectively like writing:
  ```bash
  axel -q -s 0 https://i.redd.it/img1.png https://i.redd.it/img2.jpg ...
  ```

---

### 🔹 `-q`

- **Quiet mode** – suppresses most of the output (like progress bars or status info).
- Useful for scripting or when you want clean logs.

---

### 🔹 `-s 0`

- **Skip already downloaded files** (if `-s` is used with a value greater than `0`, it starts at that byte offset).
- `-s 0` means **start from the beginning** of the file — basically, this disables resuming and ensures a **full fresh download**.

---

### ✅ Complete Use Case

This line:
```bash
axel -q -s 0 $(cat links.txt)
```
means:

> "Download all URLs from `links.txt` **quietly**, **starting from byte 0** for each file (i.e., don’t resume), using the `axel` downloader."

---

### 🛠️ Better Alternative for Multiple Files

While the above works, **`axel` doesn't handle multiple files as gracefully as `xargs`**. A more reliable and parallel-friendly version would be:

```bash
cat links.txt | xargs -n 1 -P 5 axel -n 10 -q -s 0
```

- `-n 1` = one URL per `axel` call
- `-P 5` = run 5 downloads in parallel
- `-n 10` (inside `axel`) = use 10 connections per file
- `-q -s 0` = same as explained above
