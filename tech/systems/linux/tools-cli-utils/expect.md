# cli: expect

<!--TOC-->

- [Set timeout](#set-timeout)
- [Start the SSH session](#start-the-ssh-session)
- [Handle the password prompt](#handle-the-password-prompt)
- [Execute a command after login](#execute-a-command-after-login)
- [Interact with the session manually](#interact-with-the-session-manually)
  - [Example 2: Using `pass` (or `gopass`)](#example-2-using-pass-or-gopass)
    - [Running the Script](#running-the-script)
    - [Useful Tags](#useful-tags)
    - [Additional Resources](#additional-resources)

<!--TOC-->

# Set timeout

set timeout -1

# Start the SSH session

spawn ssh user@hostname

# Handle the password prompt

expect "password:"
send "your_password\\r"

# Execute a command after login

expect "$ "
send "ls -l\\r"

# Interact with the session manually

interact

````

### Example 1: Using Environment Variables

```tcl
#!/usr/bin/expect -f

# Set timeout
set timeout -1

# Retrieve environment variables
set user $env(USERNAME)
set host $env(HOST)
set password $env(PASSWORD)

# Start the SSH session
spawn ssh $user@$host

# Handle the password prompt
expect "password:"
send "$password\r"

# Execute a command after login
expect "$ "
send "ls -l\r"

# Interact with the session manually
interact
````

### Example 2: Using `pass` (or `gopass`)

```tcl
#!/usr/bin/expect -f

# Set timeout
set timeout -1

# Retrieve password from pass
set password [exec pass show my_password_store]

# Start the SSH session
spawn ssh user@hostname

# Handle the password prompt
expect "password:"
send "$password\r"

# Execute a command after login
expect "$ "
send "ls -l\r"

# Interact with the session manually
interact
```

#### Running the Script

1. Save the script to a file (e.g., `ssh_login.expect`).
1. Make the script executable:

```bash
chmod +x ssh_login.expect
```

1. Execute the script:

```bash
./ssh_login.expect
```

#### Useful Tags

- **#expect**
- **#automation**
- **#unix**
- **#scripting**
- **#interactive**
- **#testing**

#### Additional Resources

- [Expect Man Page](<>)
- [Expect Official Documentation](<>)

By using Expect, you can automate and test applications that require user interaction, making it a powerful tool for managing and testing interactive scripts.
