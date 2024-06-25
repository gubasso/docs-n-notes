# Linux General Utilities

<!-- toc -->

  - [xprop](#xprop)
  - [tar](#tar)
  - [stow](#stow)
- [awk](#awk)
- [jq](#jq)
- [curl](#curl)
- [NetworkManager](#networkmanager)
- [time](#time)
- [xsv](#xsv)
- [mlr Miller](#mlr-miller)
- [split](#split)
- [shred / secure-delete](#shred--secure-delete)
- [xargs](#xargs)
- [rsync](#rsync)
  - [general](#general)
  - [examples](#examples)
- [sxhkd](#sxhkd)
- [ffmpeg](#ffmpeg)
- [tmux](#tmux)
- [General](#general)
  - [sum numbers from a file](#sum-numbers-from-a-file)
  - [bulk rename](#bulk-rename)
- [References:](#references)

<!-- tocstop -->

## xprop

get the window name / properties (help to setup picom, window compositor)

## tar

Person:
- compact all files in dir with tar gz

ChatGPT:
- To compact all files in a directory into a `.tar.gz` archive using the command line, you can use the `tar` command. The `tar` command is a standard on Unix-like systems and is used for creating and manipulating archive files.

Here's a basic command structure to create a `.tar.gz` archive:

```bash
tar -czvf name-of-archive.tar.gz /path/to/directory
```

Breaking down the command:
- `tar`: This is the command name for creating archives.
- `-c`: This option stands for "create", indicating that you want to create an archive.
- `-z`: This option tells `tar` to compress the archive using gzip.
- `-v`: This stands for "verbose". It's optional and when used, `tar` will list all files it's adding to the archive.
- `-f`: This option allows you to specify the filename of the archive.

For example, if you have a directory named `myfiles` in your current directory and you want to create an archive called `myfiles.tar.gz`, you would use:

```bash
tar -czvf myfiles.tar.gz myfiles
tar --exclude='.git' --exclude='target' -czf repo_files.tar.gz -C /path/to/your/repo_dir .
tar --exclude='.git' --exclude='target' -czvf repo_files.tar.gz repo_dir
```

Person:
- and how to get all files

ChatGPT:
- To extract all files from a `.tar.gz` archive, you use the `tar` command with different options. Here's how you can do it:

```bash
tar -xzvf name_of_archive.tar.gz -C /path/to/destination
```



Breaking down this command:
- `tar`: This is the command name for working with archives.
- `-x`: This option stands for "extract", indicating that you want to extract files from an archive.
- `-z`: This option tells `tar` to uncompress the archive using gzip.
- `-v`: This stands for "verbose". It's optional and when used, `tar` will list all files it's extracting.
- `-f`: This option allows you to specify the filename of the archive.
- `-C /path/to/destination`: This is also optional. It specifies the directory where you want to extract the files. If omitted, files will be extracted to the current directory.

For example, if you have an archive named `myfiles.tar.gz` and you want to extract its contents to a directory named `myfiles`, you would use:

```bash
tar -xzvf myfiles.tar.gz -C myfiles
```

- If you want to create a `.tar.gz` archive of all files within a directory, without preserving the directory structure (i.e., just the files, not the folders), you can do this by navigating to the directory and using the `tar` command with a glob pattern. Here's how to do it:
1. First, navigate to the directory containing the files you want to archive:

```bash
cd /path/to/directory
```
2. Then, use the `tar` command with a glob pattern to match all files in the current directory:

```bash
tar -czvf ../name-of-archive.tar.gz *
```

## stow

Manage dotfiles with stow.

Common command:

- create all symlink from `.dotfiles` to `~`, for every dir inside dotfiles `*`
- go to `~/.dotfiles`, run the command:

```
stow -vt ~ *
stow -vt / zsh
```

**FLAGS:**

- `-n`: for checking, no do, just show before, simulation mode
- `-v`: verbose
- `-`: target directory must be `~`
- `*`: everything... all dirs inside .dotfiles
- `--adopt`: adopt all the conflicts... it moves the original under home dir, and copies it to our .dotfile directory

stow never overrides anything

# [awk](./linux-utils-awk.md)

# jq

https://jqplay.org/
https://programminghistorian.org/en/lessons/json-and-jq

Filter/select a subset of fields from an object: https://stackoverflow.com/a/68664471

```
curl "https://api.airtable.com/v0/${airtable_base_id}/${airtable_table_variaveis}?maxRecords=3&view=Grid%20view" \
-H "Authorization: Bearer ${AIRTABLE_API_KEY}" \
| jq -c "[.records[] | {id, fields}]"
```

```
$ cat file.json | jq -c '.users[] | {first}'
{"first":"Stevie"}
{"first":"Michael"}
```

# curl

Multiple parameters:

```
curl \
    --data-urlencode "paramName=value" \
    --data-urlencode "secondParam=value" \
    http://example.com
```

Just GET request, with multiple parameters (query string):

```
curl -G "localhost:8000/tab0032" --data-urlencode 'where={"var0542": "1"}'
```
# NetworkManager

[How to force Network Manager to rescan connections?](https://superuser.com/questions/164059/how-to-force-network-manager-to-rescan-connections)

```
nmcli device wifi rescan
nmcli device wifi list
```


# time

```
time (curl -G "localhost:8000/tab0032" --data-urlencode 'where={"var0542": "1"}' &> /dev/null)
```

# xsv

csv manipulation (better than csvkit)

```
xsv index ./data/${tab}.csv
xsv split -s 10000 ./data ./data/${tab}.csv --filename ${tab}.csv.part-{}
xsv stats worldcitiespop.csv --everything | xsv table
xsv search -s var0046 "0xBb505805" data/tab0220.csv
xsv count ./data/${tab}.csv >> lines_to_sum
```

# mlr Miller

https://github.com/johnkerl/miller
Miller is like awk, sed, cut, join, and sort for data formats such as CSV, TSV, JSON, JSON Lines, and positionally-indexed.

```
mlr --icsv --ojson cat ./data/${tab}.csv > \
    ./data/${tab}.json
mlr --c2j --jvquoteall cat ./data/${tab}.csv > \
    ./data/${tab}.json
mlr --csv --quote-all cat ./data/tab0220.csv | mlr --icsv --ojson --jvquoteall cat > ./data/tab0220.json
```

conversion converter

# split

[Splitting A Large CSV Files Into Smaller Files In Ubuntu](http://burnignorance.com/linux-tips-and-tricks/splitting-a-large-csv-files-into-smaller-files-in-ubuntu/)

```
split -d -l 10000 source.csv tempfile.part.
```

# shred / secure-delete

**secure-delete**

Better than `shred`. To shred files and full directory trees.[^1]

```
sudo apt-get install secure-delete
iaur secure-delete
srm -r pathname
```

Done. Secure delete is a lot more paranoid than shred, using 38 passes instead of 3. To do a fast single pass, use

```
srm -rfll pathname
```

# xargs

- `-I`: -I allows {} to represents each file outputed from ls command

```
ls | xargs -I {} slugify {}
ls | xargs -I {} mv {} $(slugify {})

# rename files to append .old on the end of the filename
ls *old | xargs -I {} mv {} {}.old
```

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

Example of rsync being used to push/syncing files to server, with watchexec:

```
watchexec 'rsync -vurzP --delete-after ./* user@host:/full/path/'
watchexec 'rsync -vurzP --delete-after ./* user@host:relative/path/from/user/home'
rsync -vrzP --delete-after ~/website/ user@host:/var/www/html/
```

Example simple file copy

```
rsync -vurP SOURCE/ DESTINATION/
```

Example different ssh port:
```
rsync -a -e "ssh -p 2322" /opt/media/ remote_user@remote_host_or_ip:/opt/media/
```

# sxhkd

Script to kill and refresh keybindings (shortcuts). Can be used in vim, after save file.[^5](gubasso/references)

```
killall sxhkd; setsid sxhkd &
```

with vim (https://github.com/kovetskiy/sxhkd-vim)

```
autocmd BufWritePost *sxhkdrc !killall sxhkd; setsid sxhkd &
```

vimux configs:

```
" Vimux config
let g:VimuxOrientation = "v"
let g:VimuxHeight = "40"

function! VimuxInspectGoTop()
  call VimuxInspectRunner()
  call VimuxSendKeys("g")
endfunction
command -bar VimuxInspectGoTop :call VimuxInspectGoTop()

function! VimuxZoomAndInspectGoTop()
  call VimuxZoomRunner()
  call VimuxInspectGoTop()
endfunction
command -bar VimuxZoomAndInspectGoTop :call VimuxZoomAndInspectGoTop()

" Dev Workflow with Vimux
" Prompt for a command to run [^10]
nnoremap <leader>vp :wa<cr> \| :VimuxPromptCommand<cr>
" Run last command executed by VimuxRunCommand [^10]
nnoremap <leader>vl :wa<cr> \| :VimuxRunLastCommand<cr>
" Inspect runner pane [^10]
nnoremap <leader>vi :VimuxInspectGoTop<cr>
" Zoom the tmux runner pane[^10]
nnoremap <leader>vz :VimuxZoomAndInspectGoTop<CR>
" Rust workflow
" nnoremap <leader>cc :silent Redir !cargo clippy --all-targets --tests<cr>
" nnoremap <leader>ct :silent Redir !cargo test<cr>G
" nnoremap <leader>cf :silent !rustfmt %<cr>
" nnoremap <leader>cp :silent Redir !cargo play %<cr>
" call any command [^13]

augroup rust_work
    au!
    au FileType rust nnoremap <Leader>r :wa<cr> \| :VimuxPromptCommand("clrm; cargo ")<CR>
    au FileType rust nnoremap <Leader>t :wa<cr> \| :call VimuxRunCommand("clrm; cargo test -- --nocapture")<CR>
    au FileType rust nnoremap <Leader>c :wa<cr> \| :call VimuxRunCommand("clrm; cargo clippy")<CR>
augroup END
```

- [Check if Directory is Mounted in Bash](https://www.baeldung.com/linux/bash-is-directory-mounted)
    - to use with gocryptfs, script to check if vault is already mounted

# ffmpeg

OBS:
- check your display # and resolution with `xrandr` command
- check microphone with `arecord -l`

- [Stop using kazam/obs GUI tools, record screen with ffmpeg - BugsWriter](https://www.youtube.com/watch?v=1kPeAIBLrDo)
    - https://www.cnconnect.com.br/
    ```
    #!/bin/bash -x

    INRES="1920x1200"
    OUTRES="1280x720"
    FPS="30"

    ffmpeg -f x11grab -s "$INRES" -r "$FPS" -i :0.0 -f alsa -ac 2 \
    -i default -vcodec libx264 -s "$OUTRES" \
    -acodec libmp3lame -ab 128k -ar 44100 \
    -threads 0 -f flv $1
    ```

- [Automating Noise Reduction for Audio Processing](https://www.youtube.com/watch?v=f9P7SeUlzQg)
    - python, ffmpeg, sox, audacity
    - script for reduce sound as a script
    - "Would this work for you? When you record videos, you start by saying nothing for the first ten seconds. Then your script can use seconds 1-9 for obtaining the noise profile. Feed that into the sox noisered program"
    - "ffmpeg recently have been added two audio filters for denoising: afftdn and anlmdn."
        - afftdn


- [Recurrent Neural Network to reduce noise with ffmpeg](https://www.youtube.com/watch?v=CEX0JHAYgj8)
    - documentation: https://ffmpeg.org/ffmpeg-all.html#arnndn
    - very useful instructions: https://www.amirsharif.com/using-ffmpeg-to-reduce-background-noise/
    - commands:
        ```
        unzip the github models
        unzip rnnoise-models-master.zip

        extract audio from video
        ffmpeg -i inputvideo.mp4 outaudio.mp3

        arnndn command
        ffmpeg -i outaudio.mp3 -af arnndn=m=rnnoise-models-master/somnolent-hogwash-2018-09-01/sh.rnnn a.wav

        combine original video with new audio
        ffmpeg -i inputvideo.mp4 -i a.wav -c:v copy -map 0::v:0 -map 1:a:0 new.mp4

        extracting just the noise from audio
        ffmpeg -i inputaudio.mp3 -af arnndn=m=rnnoise-models-master/beguiling-drafter-2018-08-30/bd.rnnn:mix=-1 begdra-1.mp3
        ```

- [(FFMPEG) HOW TO NORMALIZE AUDIO?](https://www.youtube.com/watch?v=Kb2JEYFyvqs)
    - `ffmpeg -i  input.mp3 -af loudnorm=I=-16:LRA=11:TP=-1.5 output.mp3`

# tmux

$tmux (later):
https://github.com/tmux-plugins/tmux-resurrect
https://github.com/tmux-plugins/tmux-open

plugins:
manage sessions / shortcuts: https://github.com/tmux-plugins/tmux-sessionist
save / log / “screen capture” to a file / save history: https://github.com/tmux-plugins/tmux-logging
Restore tmux environment after system restart: https://github.com/tmux-plugins/tmux-resurrect

# General

## sum numbers from a file

Each line is a number, sum them all:

```
paste -s -d+ lines_to_sum | \bc
```

## bulk rename

- Bulk rename files
    - [Bulk rename files with vim](./it/vim-neovim.md#bulk-rename-files-with-vim)


---

(rust alternatives)

- https://github.com/eza-community/eza (ls / tree alternative)
► https://github.com/sharkdp/bat - bat (cat alternative)
► https://github.com/BurntSushi/ripgrep - ripgrep (rg) (grep alternative)
► https://github.com/sharkdp/fd - fd (find alternative)
► https://github.com/XAMPPRocky/tokei - tokei (LoC, lines of code, code count, statistics about your code)
► https://github.com/dalance/procs - procs (ps alternative)
- Zellij (rust) - A terminal multiplexer workspace with batteries included https://www.reddit.com/r/rust/comments/mwukhz/zellij_a_terminal_multiplexer_workspace_with/?utm_medium=android_app&utm_source=share (like tmux alternative)

# References:

[^1]: [How do I recursively shred an entire directory tree?](https://unix.stackexchange.com/a/146078)
