# openSUSE Build Service

> https://build.opensuse.org/
> https://openbuildservice.org/

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
