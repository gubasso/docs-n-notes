# openSUSE Build Service

> https://build.opensuse.org/
> https://openbuildservice.org/

- Tutorials:
  - *** [Open Build Service: User Guide](https://openbuildservice.org/help/manuals/obs-user-guide/)
  - [openSUSE:Build Service Tutorial](https://en.opensuse.org/openSUSE:Build_Service_Tutorial)

- [openSUSE Build Service Cheat Sheet](https://en.opensuse.org/images/d/df/Obs-cheat-sheet.pdf)
- [openSUSE:Packaging guidelines](https://en.opensuse.org/openSUSE:Packaging_guidelines)
  - [openSUSE:Packaging checks](https://en.opensuse.org/openSUSE:Packaging_checks)
  - [openSUSE:Specfile guidelines](https://en.opensuse.org/openSUSE:Specfile_guidelines)
    - Specfile Template
    - [openSUSE:Packaging Conventions RPM Macros](https://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros)
    - [openSUSE:Package source verification](https://en.opensuse.org/openSUSE:Package_source_verification)
      - keyring
      - hello example: `So looking at GNU Hello (RPM package "hello"):`

## General

```
Sometimes, you will see the obs://DOMAIN/PROJECT notation. The obs:// schema is a shorthand to abbreviate the long URL and needs to be replaced by the real OBS instance URL.
```

## openSUSE Commander (OSC)

> `osc`

- [openSUSE:OSC](https://en.opensuse.org/openSUSE:OSC)
- [openSUSE/osc](https://github.com/openSUSE/osc)


## Workflow

- Contribution:
  - Go to the package page
  - Create a branch on my home
  - Change the spec file to apply the patch (Patch0: ...)
  - Apply patch to my home branch
  - Wait for the changes
  - Submit the patch to the origin

## clone and check out an existing package

To clone and check out an existing package from the Open Build Service (OBS) into your OBS home project using the `osc` command-line tool, you can follow these steps:
1. **Branch or Copy the Package into Your Home Project:**
You have two options to get the package into your home project:

  - **Option A: Use `osc branch`** The `osc branch` command creates a personal branch of the package, preserving its link to the original project.

```bash
osc branch [source_project] [package_name] [target_project] [target_package_name]
```
**Example:**

```bash
osc branch openSUSE:Factory example-package home:yourusername example-package
```
This command branches `example-package` from `openSUSE:Factory` into your home project `home:yourusername`.

  - **Option B: Use `osc copypac`** The `osc copypac` command copies the package without preserving any link to the original.

```bash
osc copypac [source_project] [package_name] [target_project]
```
**Example:**

```bash
osc copypac openSUSE:Factory example-package home:yourusername
```

2. **Check Out the Package from Your Home Project:** Once the package is in your home project, you can check it out using the `osc checkout` command.

```bash
osc checkout [target_project] [package_name]
```
**Example:**

```bash
osc checkout home:yourusername example-package
```

3. **Navigate to the Checked-Out Package Directory:**
Change into the directory of the checked-out package to start working on it.


```bash
cd home:yourusername/example-package
```
**Summary of Commands:**

```bash
# Option A: Branching the package
osc branch [source_project] [package_name] [target_project] [target_package_name]
osc checkout [target_project] [package_name]
cd [target_project]/[package_name]

# Option B: Copying the package
osc copypac [source_project] [package_name] [target_project]
osc checkout [target_project] [package_name]
cd [target_project]/[package_name]
```
**Notes:**
- Replace `[source_project]`, `[package_name]`, `[target_project]`, and `[target_package_name]` with the actual project names and package names.

- Using `osc branch` is recommended if you plan to contribute back, as it keeps a link to the original package.

- If you only need a standalone copy for personal use, `osc copypac` might suffice.
**Additional Resources:**
- For more information on `osc` commands, you can consult the `osc` manual:

```bash
osc help
osc help branch
osc help copypac
```

By following these steps, you can successfully clone and check out an existing OBS package into your OBS home project using the `osc` command-line tool.
