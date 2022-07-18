# Shell
> $shell $zsh $bash $terminal

https://explainshell.com/ : write down a command-line to see the help text that matches each argument

Shell (bash, zsh..) command `set -C`

```
set -C
# or
set noclobber
```

- Prevent output redirection using ‘>’, ‘>&’, and ‘<>’ from overwriting existing files. [^6](gubasso/references)

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

