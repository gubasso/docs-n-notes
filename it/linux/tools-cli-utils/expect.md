# cli: expect

<!-- toc -->

- [Example 1: Using Environment Variables](#example-1-using-environment-variables)
- [Example 2: Using `pass` (or `gopass`)](#example-2-using-pass-or-gopass)

<!-- tocstop -->

**Expect**  is a Unix automation and testing tool that scripts interactions with programs that require user input. It automates responses to prompts and can be used to handle scripts and commands that typically require manual input.

#### Key Features:

- Automates interactive applications.
- Provides control over command execution and responses.
- Enables testing of command-line tools and scripts.

#### Basic Syntax:

```bash
expect [options] [script-file]
```

#### Common Options:

- `-d` : Enables debugging.
- `-c` : Executes commands directly from the command line.
- `-f` : Specifies a script file to execute.

#### Basic Commands:

- `spawn` : Starts a new process.
- `expect` : Waits for specific output from the spawned process.
- `send` : Sends a response to the spawned process.
- `interact` : Allows manual interaction with the process after automation steps.

#### Example Script:

This script automates an SSH login and executes a command:

```tcl
#!/usr/bin/expect -f

# Set timeout
set timeout -1

# Start the SSH session
spawn ssh user@hostname

# Handle the password prompt
expect "password:"
send "your_password\r"

# Execute a command after login
expect "$ "
send "ls -l\r"

# Interact with the session manually
interact
```

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
```


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


#### Running the Script:

1. Save the script to a file (e.g., `ssh_login.expect`).
2. Make the script executable:

```bash
chmod +x ssh_login.expect
```
3. Execute the script:

```bash
./ssh_login.expect
```

#### Useful Tags:

- **#expect**
- **#automation**
- **#unix**
- **#scripting**
- **#interactive**
- **#testing**

#### Additional Resources:

- [Expect Man Page]()
- [Expect Official Documentation]()

By using Expect, you can automate and test applications that require user interaction, making it a powerful tool for managing and testing interactive scripts.

