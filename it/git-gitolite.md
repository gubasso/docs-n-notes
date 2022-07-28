# Gitolite
> https://gitolite.com/gitolite/

<!-- vim-markdown-toc GFM -->

* [Dictionary](#dictionary)
* [Instalation and setup[^2]](#instalation-and-setup2)
* [Admin Tasks](#admin-tasks)
    * [adding users and repos[^3]](#adding-users-and-repos3)
        * [Users: Add new users](#users-add-new-users)
        * [Users: Remove a user](#users-remove-a-user)
        * [Repos: Create new repos and manage users access](#repos-create-new-repos-and-manage-users-access)
        * [Repos: Add existing repo (Migrate repository)](#repos-add-existing-repo-migrate-repository)
        * [Repos: Moving servers](#repos-moving-servers)
        * [Repos: removing/renaming a repo](#repos-removingrenaming-a-repo)
    * [Access Rules](#access-rules)
        * [Basic example:](#basic-example)
    * [Groups](#groups)
* [Normal Usage (project/normal user)](#normal-usage-projectnormal-user)
* [Advanced Cases](#advanced-cases)
    * [separating "key admin" from "repo admin"](#separating-key-admin-from-repo-admin)
    * [Automation: Gitolite Triggers / Git Hooks](#automation-gitolite-triggers--git-hooks)
    * [Automation: "My own" Commands](#automation-my-own-commands)
    * [Constraints: add additional constraints to a push (VREF)](#constraints-add-additional-constraints-to-a-push-vref)
* [References](#references)

<!-- vim-markdown-toc -->

## Dictionary

- **workstation:** my personal computer a.k.a. client
- **server:** vps/remote server
- **hosting user:** This is the user whose name goes into the repo URLs your users will be cloning, for example
    - `ssh://git@server/repo`
    - `git@server:repo`
    - Usually, this is `git`
- **logical repo name**: within the conf file
    - logical repo name `foo` will be `$HOME/repositories/foo.git`
    - `bar/baz`-> `$HOME/repositories/bar/baz.git`
- **ref:** branch or tag
- **refex:** a regex that matches a ref

## Instalation and setup[^2]

- enter server as your user admin

- install dependencies[^4]
    - git
    - perl
    - openssh

- create and setup user `git`[^1]
    - a dedicated userid to host the repos
    - this user id does NOT currently have any ssh pubkey-based access
    - ideally, this user id has shell access ONLY by `su - git` from some other userid on the same server (this ensure minimal confusion for ssh newbies!)

- login as `git` with `su - git`
    - gitolite must be in PATH: check if `~/bin` is in `$PATH` `server:/home/git`: make sure these files/dirs do not exists `~/.gitolite.rc`
    - `~/.gitolite`
    - `~/repositories`
    - `~/.ssh/authorized_keys`

- install packages:
    - debian 11: `gitolite3`
    - arch: `gitolite`

- copy admin public key to server:/home/git/ as `<user_admin>.pub`

```
scp yourkey.pub git@yourserver.tld:˜/yourname.pub
```

- The next step is important. Ensure that your `˜/.ssh/authorized_keys` file is empty.

- Finally, setup gitolite with yourself as the administrator:

```
$HOME/bin/gitolite setup -pk YourName.pub
```

## Admin Tasks

Basic administration is done within `gitolite-admin` repo.

- At workstation

```
git clone git@host:gitolite-admin
```

After changing anything in local `gitolite-admin` repo, add/commit changes and push.

Management will be executed in push. E.g.:

- gitolite will add the new users to `~/.ssh/authorized_keys` on the server
- create a new, empty, repo called "foo".

---

```
gitolite help
```

- If you have shell on the server, you have a lot more commands available to you

### adding users and repos[^3]

Do NOT add new repos or users manually on the server.

#### Users: Add new users

Copy `<user>.pub` to `gitolite-admin/keydir`

[multiple keys per user](https://gitolite.com/gitolite/basic-admin#multiple-keys-per-user)

- `keydir/alice.pub`
    - = `keydir/home/alice.pub`
    - = `keydir/laptop/alice.pub`

[appendix 2: old style multi-keys](https://gitolite.com/gitolite/basic-admin#appendix-2-old-style-multi-keys)

#### Users: Remove a user

```
git rm keydir/alice.pub
```

- Commit and push the changes

#### Repos: Create new repos and manage users access

Users must have been already added to `keydir`

**`conf/gitolite.conf`**
```
repo foo
    RW+         =   alice
    RW          =   bob
    R           =   carol
```

- multiple repos with same access rules

**`conf/gitolite.conf`**
```
repo foo bar
    RW+         =   alice
```

- multiple with repo group

**`conf/gitolite.conf`**
```
@myrepos    =   foo
@myrepos    =   bar
    .
    .
    .
@myrepos    =   zzq

repo @myrepos
    RW+     =   alice
```

- Reponames can contain `/` characters (this allows you to put your repos in a tree-structure for convenience).

---

include files

**`conf/gitolite.conf`**
```
include "foo.conf"
```

- You can also use a glob (`include "*.conf"`), or put your include files into subdirectories of "conf" (`include "foo/bar.conf"`), or both (`include "repos/*.conf"`).

#### Repos: Add existing repo (Migrate repository)

[Gitolite: appendix 1: bringing existing repos into gitolite](https://gitolite.com/gitolite/basic-admin#appendix-1-bringing-existing-repos-into-gitolite)

#### Repos: Moving servers

[moving servers](https://gitolite.com/gitolite/install#moving-servers)

#### Repos: removing/renaming a repo

- https://gitolite.com/gitolite/basic-admin#removingrenaming-a-repo

**removing**

- Remove repo block from `conf/gitolite.conf`
- Commit and push it
- Login to server
- delete repo from `$HOME/repositories`

**renaming**

- Go to the server and rename the repo at the Unix command line. Don't forget to retain the ".git" extension on the directory name.
- Change the name in the conf/gitolite.conf file in your gitolite-admin repo clone, and add/commit/push.

### Access Rules

- Full rules at: [Gitolite: access rules](https://gitolite.com/gitolite/conf#access-rules)

#### Basic example:

**`conf/gitolite.conf`**
```
repo foo
    RW+                     =   alice
    -   master              =   bob
    -   refs/tags/v[0-9]    =   bob
    RW                      =   bob
    RW  refs/tags/v[0-9]    =   carol
    R                       =   dave
```

- alice can do anything to any branch or tag -- create, push, delete, rewind/overwrite etc.
- bob can create or fast-forward push any branch whose name does not start with "master" and create any tag whose name does not start with "v"+digit.
- carol can create tags whose names start with "v"+digit.
- dave can clone/fetch.


### Groups

**`conf/gitolite.conf`**
```
@staff      =   alice bob carol
@interns    =   ashok

repo secret
    RW      =   @staff

repo foss
    RW+     =   @staff
    RW      =   @interns
```

**`conf/gitolite.conf`**
```
@developers     =   dilbert alice wally
@foss-repos     =   git gitolite

repo @foss-repos
    RW+         =   @developers
```

**`conf/gitolite.conf`**
```
repo foo bar

    RW+                     =   alice @teamleads
    -   master              =   dilbert @devteam
    -   refs/tags/v[0-9]    =   dilbert @devteam
    RW+ dev/                =   dilbert @devteam
    RW                      =   dilbert @devteam
    R                       =   @managers
```

---

- Group lists accumulate.


**`conf/gitolite.conf`**
```
@staff      =   alice bob carol
@developers     =   dilbert alice wally
```

is equal to:


**`conf/gitolite.conf`**
```
@staff      =   alice bob
@staff      =   carol
```

---

**`conf/gitolite.conf`**
```
@developers     =   dilbert alice
@interns        =   ashok
@staff          =   @interns @developers
@developers     =   wally

# wally is NOT part of @staff
```

---

- You can also use group names in other group names:

**`conf/gitolite.conf`**
```
@all-devs   =   @staff @interns
```

---

- `@all` is a special group name that is often convenient to use if you really mean "all repos" or "all users".


## Normal Usage (project/normal user)

Get server infos:

```
ssh git@host info
```

Help with commands:

```
ssh git@host help
```

-  All commands respond to a single argument of "-h" with suitable information.

---

E.g.: Bob wants to clone and work in a repo he's added and authorized. In Bob's workstation:

```
git clone git@host:foo
```

- NOTE: again, if they are asked for a password, something is wrong.

## Advanced Cases

- ["non-core" gitolite](https://gitolite.com/gitolite/non-core)

- Commands can be run from the shell command line. Among those, the ones in the ENABLE list in the rc file can also be run remotely.
- Hooks are standard git hooks.
- Sugar scripts change the conf language for your convenience. The word sugar comes from "syntactic sugar".
- Triggers are to gitolite what hooks are to git. I just chose a different name to avoid confusion and constant disambiguation in the docs.
- VREFs are extensions to the access control check part of gitolite.

### [separating "key admin" from "repo admin"](https://gitolite.com/gitolite/cookbook#separating-key-admin-from-repo-admin)

### Automation: Gitolite Triggers / Git Hooks

- [gitolite triggers](https://gitolite.com/gitolite/triggers)
- [appendix B: making a trigger run after the built-in ones](https://gitolite.com/gitolite/rc#appendix-b-making-a-trigger-run-after-the-built-in-ones)
- [triggers / adding your own triggers](https://gitolite.com/gitolite/cookbook#triggers)

- [Git Hooks](https://gitolite.com/gitolite/cookbook#hooks)
    - adding your own update hooks
    - adding other (non-update) hooks
    - variation: maintain these hooks in the gitolite-admin repo
    - (v3.6+) variation: repo-specific hooks

### Automation: "My own" Commands

- [adding your own commands / making commands available to remote users](https://gitolite.com/gitolite/cookbook#commands)

### Constraints: add additional constraints to a push (VREF)

- [virtual refs](https://gitolite.com/gitolite/vref#virtual-refs)


## References

[^1]: [Server / VPS](./it/server-vps.md)
[Setup a server / vps / domain name / security measures](#setup-a-server-vps-domain-name-security-measures)
    * [manage security](#manage-security)
        * [add a new user and set a password [^l1]](#add-a-new-user-and-set-a-password-l1)
[^2]: [Gitolite: Installation and setup](https://github.com/sitaramc/gitolite#installation-and-setup)
[^3]: [Gitolite: adding users and repos](https://github.com/sitaramc/gitolite#adding-users-and-repos)
[^4]: [Gitolite: install and setup](https://gitolite.com/gitolite/install#your-server)
[^5]: [Use Gitolite To Setup Git Repositories on Debian](https://www.vultr.com/docs/setup-git-repositories-with-gitolite-on-debian-wheezy/)
