# Shell
> $shell $zsh $bash $terminal


<!-- toc GFM -->

* [General](#general)
* [read stdin in function in bash script ](#read-stdin-in-function-in-bash-script-)
* [Key-value pair](#key-value-pair)
* [Files maching list of files](#files-maching-list-of-files)
* [Case statement](#case-statement)
* [Loop](#loop)
* [Parameter Expansion](#parameter-expansion)
* [Flags](#flags)
  - [shflags](#shflags)

<!-- toc -->

- [General](#general)
- [read stdin in function in bash script](#read-stdin-in-function-in-bash-script-)
- [Key-value pair](#key-value-pair)
- [Files maching list of files](#files-maching-list-of-files)
- [Case statement](#case-statement)
- [Loop](#loop)
- [Parameter Expansion](#parameter-expansion)
- [Flags](#flags)
  - [shflags](#shflags)

<!-- tocstop -->

## General

Functions to work with issues (bug issue tracker) and git:

```sh
# bug commit close issue (bcc)
# bug commit WIP issue (bcw)
function bcc() {
    issue="$(fd . -td issues | fzf)"
    closed_issues_dir="_closed/issues"
    if [ ! -d "$closed_issues_dir" ]; then
        mkdir -p $closed_issues_dir
    fi
    if [[ ! $issue ]]; then
        echo "No issue selected"
    else
        mv $issue $closed_issues_dir
        git add $issue $closed_issues_dir && git commit -m "closes: $issue"
    fi
}

function bcw() {
    issue="$(fd . -td issues | fzf)"
    if [[ ! $issue ]]; then
        echo "No issue selected"
    elif [[ ! $(gstaged) ]]; then
        echo "No staged files to commit $issue"
    else
        git add $issue && git commit -m "(WIP) $issue"
    fi
}

function bcc() {
    issue="Issue: $(bug list ${@} | awk -F ': ' '/Title/ {print $2}')"
    if [[ $(gstaged) ]]; then
        git commit -m "(locked) ${issue}"
        bug close $@ && git add -A && git commit -m "(closed) ${issue}"
        git push
    else
        echo "No staged files to close ${issue}"
    fi
}
```


[Linux Run Command As Another User](https://www.cyberciti.biz/open-source/command-line-hacks/linux-run-command-as-different-user/)
```
runuser -u www-data -- command
## Run commands as www-data user ##
runuser -u www-data -- composer update --no-dev
runuser -u www-data -- php7 /app/maintenance/update.php
```

---

running process
ctrl+z
process running and paused in background
bg (check background process)
disown (disown process from shell and it keeps running in background)

---

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

## Case statement

```
function list_csvs() {
    case ${1} in
        in)
            grep_flag="-f"
            ;;
        out)
            grep_flag="-vf"
            ;;
        *)
            echo 'Second arg must be "in" or "out".'
            ;;
    esac

    find . -name "*.csv" | \
        xargs -n 1 basename | \
        grep ${grep_flag} ${2}
}
```

- For each yaml file
- echo its content, separated by its filename
```sh
find . -name "*.yaml" -print0 | xargs -0 -I {} sh -c 'echo "# ==> {} <=="; cat {}; echo' | toxclip
```

```bash
find . -name "*.md" -type f -print0 | xargs -0 cat
find . -name "*.md" -print0 | xargs -0 -I {} sh -c 'echo "# ==> {} <=="; cat {}; echo' | toxclip
```

- `find .` starts the search in the current directory (`.`).
- `-name "*.md"` looks for files ending with the `.md` extension.
- `-type f` ensures that only files (not directories) are considered.
- `-print0` outputs the file names followed by a null character instead of a newline. This is useful to handle filenames with spaces or newlines correctly.
- `xargs -0 cat` takes the null-terminated file names from `find` and uses `cat` to output their contents. The `-0` option tells `xargs` to expect input items terminated by a null character, matching `-print0` from `find`.


## Loop

How can I loop over the output of a shell command?
https://stackoverflow.com/questions/35927760/how-can-i-loop-over-the-output-of-a-shell-command

```
pgrep -af python | while read -r line ; do
    echo "$line"
done

# in a function

function convert_fmt_to_quotes() {
    while read -r csv_fileext_path ; do
        cp  ${csv_fileext_path} ${csv_fileext_path}.tmp
        xsv fmt --quote-always ${csv_fileext_path}.tmp > ${csv_fileext_path}
        rm ${csv_fileext_path}.tmp
    done
}

find ${datapath} -name "${csv_fileext}.part*" | sort | \
  tee >(convert_fmt_to_quotes) | \
  while read -r part_fileext_path ; do
   # ...
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
