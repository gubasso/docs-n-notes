# Shell
> $shell $zsh $bash $terminal

<!-- vim-markdown-toc GFM -->

* [General](#general)
* [read stdin in function in bash script ](#read-stdin-in-function-in-bash-script-)
* [Key-value pair](#key-value-pair)
* [Files maching list of files](#files-maching-list-of-files)
* [Loop](#loop)
* [Parameter Expansion](#parameter-expansion)
* [Flags](#flags)
    * [shflags](#shflags)

<!-- vim-markdown-toc -->

## General

`!!` command

```
sudo systemctl status sshd
!!:s/status/start/ #substitutes
```

---

https://explainshell.com/ : write down a command-line to see the help text that matches each argument

Shell (bash, zsh..) command `set -C`

```
set -C
# or
set noclobber
```

- Prevent output redirection using ‘>’, ‘>&’, and ‘<>’ from overwriting existing files. [^6](gubasso/references)


## [read stdin in function in bash script ](https://stackoverflow.com/questions/14004756/read-stdin-in-function-in-bash-script)

```
function myeggs() {
    while read -r data; do
        echo "${data}"
    done
}

ls | myeggs
```

## Key-value pair
> key value variable

[How to Use Key-Value Dictionary in Shell Script](https://fedingo.com/how-to-use-key-value-dictionary-in-shell-script/)

- `declare` inside function is local variable






## Files maching list of files

[find files not in a list](https://stackoverflow.com/questions/7306971/find-files-not-in-a-list)

```
find -mtime +7 -print | grep -Fxvf file.lst
```

Where:

```
-F, --fixed-strings
              Interpret PATTERN as a list of fixed strings, separated by newlines, any of which is to be matched.    
-x, --line-regexp
              Select only those matches that exactly match the whole line.
-v, --invert-match
              Invert the sense of matching, to select non-matching lines.
-f FILE, --file=FILE
              Obtain patterns from FILE, one per line.  The empty file contains zero patterns, and therefore matches nothing.
```


## Loop

How can I loop over the output of a shell command?
https://stackoverflow.com/questions/35927760/how-can-i-loop-over-the-output-of-a-shell-command

```
pgrep -af python | while read -r line ; do
    echo "$line"
done
```

## Parameter Expansion

[How to Get Filename from Path in Shell Script](https://fedingo.com/how-to-get-filename-from-path-in-shell-script/)
- has simple examples

```
dir=$(dirname ${full})
file_with_ext="${full##*/}"
file_no_ext="${file_with_ext%.*}"
```

Nice tutorial: [Introduction to Bash Shell Parameter Expansions](https://linuxconfig.org/introduction-to-bash-shell-parameter-expansions )

Nice summary table:[Bash Parameter Expansion](https://linuxhint.com/bash_parameter_expansion/ )

Other nice ways to [Extract filename and extension in Bash ](https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash)

```
variable_to_be_expanded="/my/eggs/lala.txt"
echo "${variable_to_be_expanded}"
```

Bash includes the POSIX pattern removal ‘%’, ‘#’, ‘%%’ and ‘##’ expansions to remove leading or trailing substrings from variable values (see [Shell Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)).


## Flags

### shflags

[ kward / shflags ](https://github.com/kward/shflags)

---

[Taking command line arguments using flags in bash ](https://dev.to/shriaas2898/taking-command-line-arguments-using-flags-in-bash-121)
- pure `getopts`
