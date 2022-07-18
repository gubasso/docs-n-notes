# Linux General Utilities

<!-- vim-markdown-toc GitLab -->

* [General](#general)
    * [sum numbers from a file](#sum-numbers-from-a-file)
    * [xsv](#xsv)
    * [mlr Miller](#mlr-miller)
    * [split](#split)
    * [bulk rename](#bulk-rename)
    * [shred / secure-delete](#shred-secure-delete)
* [xargs](#xargs)
* [rsync](#rsync)
* [sxhkd](#sxhkd)
* [ffmpeg](#ffmpeg)
* [tmux](#tmux)
* [References:](#references)

<!-- vim-markdown-toc -->

## General

### sum numbers from a file

Each line is a number, sum them all:

```
paste -s -d+ lines_to_sum | \bc
```

### xsv

csv manipulation (better than csvkit)

```
xsv index ./data/${tab}.csv
xsv split -s 10000 ./data ./data/${tab}.csv --filename ${tab}.csv.part-{}
xsv stats worldcitiespop.csv --everything | xsv table
xsv search -s var0046 "0xBb505805" data/tab0220.csv
xsv count ./data/${tab}.csv >> lines_to_sum
```

### mlr Miller

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

### split

[Splitting A Large CSV Files Into Smaller Files In Ubuntu](http://burnignorance.com/linux-tips-and-tricks/splitting-a-large-csv-files-into-smaller-files-in-ubuntu/)

```
split -d -l 10000 source.csv tempfile.part.
```


### bulk rename

- Bulk rename files
    - [Bulk rename files with vim](./it/vim-neovim.md#bulk-rename-files-with-vim)

### shred / secure-delete

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

---

Zellij (rust) - A terminal multiplexer workspace with batteries included https://www.reddit.com/r/rust/comments/mwukhz/zellij_a_terminal_multiplexer_workspace_with/?utm_medium=android_app&utm_source=share (like tmux)
rust replacement

REFERENCED:
► https://starship.rs/ - Starship Prompt
► https://the.exa.website/ - exa
► https://github.com/sharkdp/bat - bat
► https://github.com/BurntSushi/ripgrep - ripgrep (rg)
► https://github.com/sharkdp/fd - fd
► https://github.com/XAMPPRocky/tokei - tokei
► https://github.com/dalance/procs - procs

- bleach bit: clear system and browser files
- dupeguru: find and clear duplicate files
- qdirstat: stats for files and directories, find big files and directories

## xargs

- `-I`: -I allows {} to represents each file outputed from ls command

```
ls | xargs -I {} slugify {}
ls | xargs -I {} mv {} $(slugify {})

# rename files to append .old on the end of the filename
ls *old | xargs -I {} mv {} {}.old
```




## rsync

Example of rsync being used to push/syncing files to server, with watchexec:

```
watchexec 'rsync -vurzP --delete-after ./* gubasso@projects.cwnt.io:/home/gubasso/cadelab-api-backend/'
```

## sxhkd

Script to kill and refresh keybindings (shortcuts). Can be used in vim, after save file.[^5](gubasso/references)

```
killall sxhkd; setsid sxhkd &
```

with vim

```
autocmd BufWritePost *sxhkdrc !killall sxhkd; setsid sxhkd &
```

- [Check if Directory is Mounted in Bash](https://www.baeldung.com/linux/bash-is-directory-mounted)
    - to use with gocryptfs, script to check if vault is already mounted

## ffmpeg

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

## tmux

$tmux (later):
https://github.com/tmux-plugins/tmux-resurrect
https://github.com/tmux-plugins/tmux-open

plugins:
manage sessions / shortcuts: https://github.com/tmux-plugins/tmux-sessionist
save / log / “screen capture” to a file / save history: https://github.com/tmux-plugins/tmux-logging
Restore tmux environment after system restart: https://github.com/tmux-plugins/tmux-resurrect


## References:

[^1]: [How do I recursively shred an entire directory tree?](https://unix.stackexchange.com/a/146078)
