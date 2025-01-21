# CLI Development Conventions

When building a command-line interface (CLI) program that loads configuration variables from multiple sources—such as command-line arguments, environment variables, and configuration files—it's standard practice to establish a clear precedence among these sources. The conventional priority, from highest to lowest, is as follows:

- Command-line arguments/options: These are specified directly by the user when executing the program and should take precedence over other sources.
- Environment variables: These are set in the user's environment and provide a way to configure the program without modifying code or command-line inputs.
- Configuration files: These files contain default settings and are typically used when neither command-line arguments nor environment variables provide a value.
- This hierarchy allows users to override default configurations and environment settings on a per-execution basis using command-line arguments, while environment variables offer a way to set configurations across sessions without altering configuration files.

For example, the AWS Command Line Interface follows this precedence order:

- Command-line options override environment variables and configuration file settings.
- Environment variables override settings in configuration files.
- Configuration files provide default values when neither command-line options nor environment variables are set.

Similarly, the Oracle Cloud Infrastructure CLI applies configurations in the following order:

- Command-line options.
- Environment variables.
- Configuration file entries.

Adhering to this conventional precedence ensures flexibility and control for users interacting with your CLI program.

- `precedence: Command-line arguments > Environment Variables > Config File Defaults.`
- `cli > env_vars > config_files`

```
Command Line Interface follows this precedence order:

- Command-line options override environment variables and configuration file settings.
- Environment variables override settings in configuration files.
- Configuration files provide default values when neither command-line options nor environment variables are set.
```
