# DevOps: Ansible

<!-- toc -->

- [General](#general)
  - [General top concepts[^4]](#general-top-concepts4)
- [Roles](#roles)
- [Organization models](#organization-models)
  - [gubasso's (cwnt)](#gubassos-cwnt)
- [Organization / Best Practices [^1]](#organization--best-practices-1)
  - [Hosts](#hosts)
  - [Groups](#groups)
  - [Variables](#variables)
  - [Playbooks / Roles](#playbooks--roles)
  - [Tasks / Handlers](#tasks--handlers)
  - [Vault/Vars organization](#vaultvars-organization)
- [Ansible Vault](#ansible-vault)
  - [Run playbook](#run-playbook)
  - [File encryption](#file-encryption)
  - [Var encryption: encrypt_string](#var-encryption-encrypt_string)
- [Modules](#modules)
  - ['package'](#package)
  - ['service'](#service)
  - ['lineinfile'](#lineinfile)
  - ['user'](#user)
  - ['authorized_key'](#authorized_key)
  - ['copy'](#copy)
- [Tips](#tips)
- [References](#references)

<!-- tocstop -->

```
    Server 1       Server 2       Server 3
       |              |              |
       v              v              v
    +----------------------------------+
    |              Laptop              |
    +----------------------------------+
```

- Laptop = ansible host (can be anything)

## General

- File `inventory`
  - list of hosts/servers (organized by groups)

Check if connection is working:

```sh
ansible all -m ping
```

### General top concepts[^4]

- **Roles**:
  - Templating configuration to be repeated over and over again
  - Write one and run in multiple playbooks
  - 1 to many relationship
  - Isolate very specific and complex work
  - Can be pulled to multiple environments and playbooks
- **Playbooks**:
  - Represents an entire specific solution, a whole implementation
  - Consumes multiple roles and dependencies (db, webserver, system dependencies, shared filesystem, etc...)
  - E.g. `wordpress.yml`: implements and manages the whole wordpress solution
    - E.g.: `drupal.yml`
- **Ansible Vault**: must use
- **Modules**:
  - if a role/playbook or set of tasks are too complex, consider writing a module
  - it's simple, can be written in any programming language


## Roles

> https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html


- Set/Group of tasks for specific setup
- group your content into role
- easily reuse them and share them with other users
- automatically load related vars, files, tasks, handlers, and other Ansible artifacts based on a known file structure

Examples:

- "common": common role that is applied for everybody

## Organization models

### gubasso's (cwnt)

Project structure:[^1]

```
production         # inventory file for production servers
staging            # inventory file for staging environment

site.yml           # master playbook
webservers.yml     # playbook for webserver tier
dbservers.yml      # playbook for dbserver tier

group_vars/
  group1/
    vars
    vault
  group2/
    ...
host_vars/
  hostname1/
    vars
    vault
  hostname2
    ...

roles/
    common/               # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case
```

- `hostname1`
  - vars: public
  - vault: private [^2]

Variable naming pattern:

```ini
ansible_user = {{ vaul_ansible_user }}
ansible_ssh_private_key_file = {{ vaul_ansible_ssh_private_key_file }}
ansible_port = {{ vault_ansible_port }}
ansible_become_password = {{ vault_ansible_become_password }}
```

## Organization / Best Practices [^1]

### Hosts

- host_vars/[host_name]/{vars.yml,vault.yml}

[Adding ranges of hosts](https://docs.ansible.com/ansible/2.9/user_guide/intro_inventory.html#adding-ranges-of-hosts)

In INI:

```ini
[webservers]
www[01:50].example.com

[databases]
db-[a:f].example.com
```

```yml
...
  webservers:
    hosts:
      www[01:50].example.com:
```

### Groups

- Group By Roles
  - e.g.: webservers, dbservers, etc...


Dynamic groups:

```yml
---

 - name: talk to all hosts just so we can learn about them
   hosts: all
   tasks:
     - name: Classify hosts depending on their OS distribution
       group_by:
         key: os_{{ ansible_facts['distribution'] }}

 # now just on the CentOS hosts...

 - hosts: os_CentOS
   gather_facts: False
   tasks:
     - # tasks that only happen on CentOS go here
```


```yml
---
# file: group_vars/all
asdf: 10

---
# file: group_vars/os_CentOS
asdf: 42
```


Alternatively, if only variables are needed:

```yml
- hosts: all
  tasks:
    - name: Set OS distribution dependent variables
      include_vars: "os_{{ ansible_facts['distribution'] }}.yml"
    - debug:
        var: asdf
```

### Variables

Organize general variables by groups.

- group_vars/[group_name]/{vars.yml,vault.yml}
- group_vars/all

```yml
---
# file: group_vars/all
ntp: ntp-boston.example.com
backup: backup-boston.example.com
```

- group_vars/backup_s3

```yml
---
backup_repository: <s3.bucket.url>
```

### Playbooks / Roles

main.yml playbook

```yml
---
# file: main.yml
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
```

Executing roles in a playbook:

```yml
---
# file: webservers.yml
- hosts: all
  roles:
    - base
- hosts: webservers
  roles:
    - common
    - webtier
# file: other
- hosts: dbservers
  become: true
  roles:
    - common
    - dbrole
```

The idea is to be able to run for evetything or for just a piece:

```sh
ansible-playbook site.yml --limit webservers
# is equals to:
ansible-playbook webservers.yml
```

### Tasks / Handlers

```yml
---
# file: roles/common/tasks/main.yml

- name: be sure ntp is installed
  yum:
    name: ntp
    state: present
  tags: ntp

- name: be sure ntp is configured
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify:
    - restart ntpd
  tags: ntp

- name: be sure ntpd is running and enabled
  service:
    name: ntpd
    state: started
    enabled: yes
  tags: ntp
```

```yml
---
# file: roles/common/handlers/main.yml
- name: restart ntpd
  service:
    name: ntpd
    state: restarted
```

### Vault/Vars organization

```yml
group_vars/
└── production/
    ├── vars.yml
    └── vault.yml
```

Sample public vars `group_vars/[group_name]/vars.yml`

```yml
---
# Public variables
ansible_user: "{{ vault_ansible_user }}"
ansible_ssh_private_key_file: "{{ vault_ansible_ssh_private_key_file }}"
ansible_port: "{{ vault_ansible_port }}"

# Other public variables
domain: crownandtrunk.com
tags:
  - production
  - to_backup
  - git_server
ssh_keys:
  sysking: "{{ vault_ssh_key_sysking }}"
  git: "{{ vault_ssh_key_git }}"
```

Sample vault vars `group_vars/[group_name]/vault.yml` (example with the whole vault encrypted, not just variables) [^2]

```sh
ansible-vault create group_vars/[group_name]/vault.yml
```

```yml
---
# Sensitive variables
vault_ansible_ssh_private_key_file: ~/path/to/private/key
vault_ssh_key_sysking: ~/path/to/private/key
vault_ssh_key_git: ~/path/to/private/key
```

## Ansible Vault

> [Protecting sensitive data with Ansible vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
  > [Managing vault passwords](https://docs.ansible.com/ansible/latest/vault_guide/vault_managing_passwords.html)
  > [Encrypting content with Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/vault_encrypting_content.html)

### Run playbook

```sh
ansible-playbook --vault-password-file /path/to/my/vault-password-file site.yml
```

### File encryption

```sh
ansible-vault create foo.yml
ansible-vault create --vault-id password1@prompt foo.yml
ansible-vault edit foo.yml
ansible-vault edit --vault-id pass2@vault2 foo.yml
ansible-vault rekey foo.yml bar.yml baz.yml
ansible-vault encrypt foo.yml bar.yml baz.yml
ansible-vault encrypt --vault-id project@prompt foo.yml bar.yml baz.yml
ansible-vault decrypt foo.yml bar.yml baz.yml
ansible-vault view foo.yml bar.yml baz.yml
```

### Var encryption: encrypt_string

Examples:

```sh
ansible-vault encrypt_string <password_source> '<string_to_encrypt>' --name '<string_name_of_variable>'
```

```yml
notsecret: myvalue
mysecret: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653236336462626566653063336164663966303231363934653561363964363833313662
          6431626536303530376336343832656537303632313433360a626438346336353331386135323734
          62656361653630373231613662633962316233633936396165386439616533353965373339616234
          3430613539666330390a313736323265656432366236633330313963326365653937323833366536
          34623731376664623134383463316265643436343438623266623965636363326136
other_plain_text: othervalue
```

- [Use encrypt_string to create encrypted variables to embed in yaml](https://docs.ansible.com/ansible/2.9/user_guide/vault.html#encrypt-string-for-use-in-yaml)

```sh
ansible-vault encrypt_string --vault-password-file a_password_file 'super secret content' --name 'secret_key'
```

Result:

```yml
secret_key: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      62313365396662343061393464336163383764373764613633653634306231386433626436623361
      6134333665353966363534333632666535333761666131620a663537646436643839616531643561
      63396265333966386166373632626539326166353965363262633030333630313338646335303630
      3438626666666137650a353638643435666633633964366338633066623234616432373231333331
      6564
```

With vault-id:

```sh
ansible-vault encrypt_string --vault-id dev@a_password_file 'foooodev' --name 'the_dev_secret'
```

```yml
the_dev_secret: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          30613233633461343837653833666333643061636561303338373661313838333565653635353162
          3263363434623733343538653462613064333634333464660a663633623939393439316636633863
          61636237636537333938306331383339353265363239643939666639386530626330633337633833
          6664656334373166630a363736393262666465663432613932613036303963343263623137386239
          6330
```

To encrypt a string read from stdin and name it ‘db_password’:

```sh
echo -n 'letmein' | ansible-vault encrypt_string --vault-id dev@a_password_file --stdin-name 'db_password'
```

```yml
# > Reading plaintext input from stdin. (ctrl-d to end input)
db_password: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          61323931353866666336306139373937316366366138656131323863373866376666353364373761
          3539633234313836346435323766306164626134376564330a373530313635343535343133316133
          36643666306434616266376434363239346433643238336464643566386135356334303736353136
          6565633133366366360a326566323363363936613664616364623437336130623133343530333739
          3039
```

To see the original (decrypted) value:

```sh
ansible localhost -m debug -a var="new_user_password" -e "@vars.yml" --ask-vault-pass
# Vault password:
#
# localhost | SUCCESS => {
#     "new_user_password": "hunter2"
# }
```

- [How do I keep secret data in my playbook?](https://docs.ansible.com/ansible/2.9/reference_appendices/faq.html#keep-secret-data)
  - prevent secrets to be logged

```yml
- name: secret task
  shell: /usr/bin/do_something --value={{ secret_value }}
  no_log: True
```

```yml
- hosts: all
  no_log: True
```

## Modules

### 'package'

- generic OS package manager
- allow same task install packages for different distros (substitutes 'apt' or 'yum', etc...)

### 'service'

> [ansible.builtin.service module – Manage services](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html)

"Controls services on remote hosts. Supported init systems include BSD init, OpenRC, SysV, Solaris SMF, systemd, upstart."

### 'lineinfile'

Change a line in a file.

Tips[^3.services]:

- when run a playbook that changes a line
- run it again, check if there is another change (it should not change anything again)
- check if the line is being added again and again

### 'user'

- Create / add / manage users and groups

### 'authorized_key'

- Manage ssh keys

### 'copy'

- Copy files to server
- Can use templates

## Tips

```yml
- hosts: all
  become: true
  pre_task:
    - name: (...)
      (...)
```

`pre_task` runs before any other tasks.

## References

- [ArchWiki: Ansible](https://wiki.archlinux.org/title/Ansible)

[^1]:https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html "Best Practices"
[^2]: https://docs.ansible.com/ansible/2.9/user_guide/vault.html#file-level-encryption "File-level encryption: Creating Encrypted Files"
[^3]: https://www.youtube.com/playlist?list=PLT98CRl2KxKEUHie1m24-wkyHpEsa4Y70 "Getting started with Ansible - Playlist - Learn Linux TV"
[^3.services]: https://youtu.be/soeBHGAMkoQ?list=PLT98CRl2KxKEUHie1m24-wkyHpEsa4Y70&t=580 "Getting started with Ansible 12 - Managing Services"
[^4]: https://www.youtube.com/watch?v=mXlzVpMUNzU "Things I wish I knew about Ansible from day 1 - Michael Crilly"
