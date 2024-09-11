# SSH Issue: ssh multiplexing denied fallthru

<!-- toc -->

## Issue description

Trying to do git operations on multiple remote gitolite repositories...
It also happened when I changed the remotes to gitlab (the issue was not with gitolite itself)

git push doesn't work... but the GIT_SSH_COMMAND="ssh -v" git push works...

```
❯ git push
FATAL: W any suse/password-store gubasso DENIED by fallthru
(or you mis-spelled the reponame)
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

```
❯ GIT_SSH_COMMAND="ssh -v" git push
OpenSSH_9.6p1, OpenSSL 3.1.4 24 Oct 2023
...
...
...
Everything up-to-date
```

at the repo:

```
❯ git config --list
user.email=gustavo.basso@suse.com
user.name=Gustavo Basso
core.sshcommand=ssh -oControlMaster=auto -oControlPersist=600 -oControlPath=/tmp/.ssh-%C
...
...
...
```

### Basic issue explanation and possible solutions

ChatGPT:

Based on the information you've provided, it seems that the default `git push` command fails because the SSH connection isn't being established correctly. However, when you specify the `GIT_SSH_COMMAND="ssh -v"` environment variable, the `git push` works as expected. The primary difference here is the verbosity and perhaps the specific configuration being loaded when you manually specify the SSH command.

1. **Custom SSH Configuration:**

Your `.ssh/config` file is likely being used when you run `GIT_SSH_COMMAND="ssh -v" git push`. This file contains custom configurations that are critical for connecting to the server correctly. Here is the relevant part from the verbose output:

```arduino
debug1: /home/gbasso/.ssh/config line 66: Applying options for gitcwnt-gbasso-suse
```
This suggests that your `.ssh/config` has a section specifically for `gitcwnt-gbasso-suse`. However, when you run `git push` without `GIT_SSH_COMMAND`, it might not be using the same configurations.

This is the default git configuration for each repo (local config):

```bash
git config core.sshCommand "ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/.ssh-%C"
```

Alternatively, you can globally set this configuration:


```bash
git config --global core.sshCommand "ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/.ssh-%C"
```

2. **SSH Control Path Issues:**

Your SSH configuration uses a control path option (`ControlPath=/tmp/.ssh-%C`), which means that SSH connection multiplexing is enabled. This can sometimes cause issues if there are leftover control master sockets or if the paths are not accessible or too long.

**Solution:**

Clean up any existing SSH control sockets:

```bash
sudo find /tmp -type s -name '.ssh-*' -delete
```
Ensure that the control path is accessible and not too long. You could also change the `ControlPath` to a simpler one, such as:

```bash
git config core.sshCommand "ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=~/.ssh/git-%r@%h:%p"
```

### Tried to solve deleting tmp cache

You:

both ids are correctly loaded at the ssh agent:

```
❯ ssh-add -l
...
...
...
...
```

at the repository "root"
```
❯ git push
Everything up-to-date
```

at the reposiroty suse
```
suse on  master
❯ git push
FATAL: W any suse/password-store gubasso DENIED by fallthru
(or you mis-spelled the reponame)
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

then I clean the temp files...

```
suse on  master
❯ sudo find /tmp -type s -name '.ssh-*' -delete
```

and try again at suse:

```
❯ git push
Everything up-to-date
```

it works correctly.... but now when I try at the repository "root"

```
root on  master
❯ git push
FATAL: W any gubasso/password-store gbasso-suse DENIED by fallthru
(or you mis-spelled the reponame)
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

it doesn't work...

### Understanding the Problem

ChatGPT:

It appears that your issue is related to SSH multiplexing and possibly some caching problems with your SSH agent or the SSH control socket files. When you delete the SSH control socket files, the push works temporarily, but it fails again when switching between repositories.

1. **SSH Control Socket and Multiplexing:**
  - You have SSH multiplexing enabled, which reuses a single SSH connection for multiple git operations. This setup is controlled by the `ControlMaster`, `ControlPath`, and `ControlPersist` options in your SSH configuration.

  - When you delete the control socket files (`/tmp/.ssh-*`), you're effectively resetting any existing SSH sessions, forcing new connections to be established.

2. **Different Repository Configurations:**
  - Each repository might be connecting to a different remote, which could require different SSH keys or different configurations. The error messages you see (`DENIED by fallthru`) suggest that the server-side access control is denying access due to incorrect identification or authorization.

3. **SSH Agent and Identity Issues:**
  - Both SSH keys are loaded into the SSH agent, but it's possible that the wrong key is being used when switching between repositories due to the multiplexed connection.

## Solutions

The problem was related to SSH multiplexing, which reuses existing SSH connections for multiple operations, potentially causing conflicts when switching between repositories.


### 0) Disable SSH multiplexing by unsetting core.sshcommand

The best solution.

```sh
git config --unset core.sshCommand
```

### 1) Disable SSH Multiplexing Temporarily (for each repo locally)

To confirm that SSH multiplexing is the issue, you can temporarily disable it for your git operations. This can be done by overriding the `core.sshCommand` for the repository.For the `root` repository:

```bash
git config core.sshCommand "ssh -o ControlMaster=no"
```
For the `suse` repository:

```bash
git config core.sshCommand "ssh -o ControlMaster=no"
```

This will disable SSH multiplexing for these repositories and force a new connection for each `git push`. If this resolves the issue, it confirms that SSH multiplexing was causing the problem.2.

Great to hear that disabling SSH multiplexing resolved the issue for you! By setting `core.sshCommand "ssh -o ControlMaster=no"` for each repository, you've effectively ensured that each `git push` operation establishes a new SSH connection without reusing an existing one. This avoids any conflicts or caching problems that may have been caused by SSH multiplexing.

By disabling SSH multiplexing (`ControlMaster=no`), each `git push` operation now creates a new SSH connection, ensuring the correct SSH identity and configuration is used for each repository.
