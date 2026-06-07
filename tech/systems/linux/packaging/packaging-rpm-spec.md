# RPM spec file guide

A practical reference for writing and maintaining `.spec` files for RPM-based distributions
(openSUSE, Fedora, RHEL, and derivatives). Covers section roles, the most useful macros,
multi-Python flavor patterns, conditional builds, and the tags that are obsolete in modern RPM.

## What a spec file is

A spec file defines how a package is built: its build/runtime dependencies, build steps, and which
files end up in the resulting RPM. Look at any well-maintained upstream package for a worked example
covering subpackages, patches, systemd macros, and `%pyproject_wheel`.

## Sections

| Section          | Purpose                                                     |
| ---------------- | ----------------------------------------------------------- |
| `BuildRequires:` | Packages needed at build time (compilers, libraries, tools) |
| `%prep`          | Unpack sources and apply patches (e.g. `%autosetup`)        |
| `%build`         | Compile stage (C, Python wheel build, etc.)                 |
| `%install`       | Install into `%{buildroot}` (e.g. `%make_install`)          |
| `%files`         | List of files that go into the final RPM                    |
| `%changelog`     | Package change history                                      |

Each `%token` is a macro. Plain shell commands work in any section — macros are optional
conveniences that adapt to distro/arch defaults.

## Evaluating macros

Use `rpm --eval` to see what a macro expands to:

```bash
rpm --eval %make_install
# → make install DESTDIR=/home/user/rpmbuild/BUILDROOT/%{NAME}-%{VERSION}-%{RELEASE}.x86_64

rpm --eval '%dir %{_datadir}/foo'
# → %dir /usr/share/foo
```

Quote the expression when it contains spaces.

## Directory macros

| Macro         | Typical value              | Notes                               |
| ------------- | -------------------------- | ----------------------------------- |
| `%{_prefix}`  | `/usr`                     | Top-level prefix; same as `%{_usr}` |
| `%{_bindir}`  | `/usr/bin`                 | Executables                         |
| `%{_libdir}`  | `/usr/lib` or `/usr/lib64` | Arch-specific libraries             |
| `%{_datadir}` | `/usr/share`               | Arch-independent data               |
| `%{_mandir}`  | `/usr/share/man`           | Man pages                           |

**Rule**: use the most specific macro. `%{_libdir}` is correct for libraries (handles 32 vs 64 bit).
Don't blindly replace `%{_usr}` with `%{_libdir}` — only library paths should use `%{_libdir}`.

Example — prefer specific macros:

```spec
%install
    install -D -m755 my-service \
        %{buildroot}%{_libdir}/<some-service>/<my-service>

%files -n <subpackage-name>
%dir %{_libdir}/<some-service>
%dir %{_libdir}/<some-service>/service
%{_libdir}/<some-service>/service/*
```

## Python `%{_sitelibdir}` pattern

For multi-flavor Python packages (`%{pythons}` = `python311`, `python312`, …), define a dynamic
site-lib macro:

```spec
%global _sitelibdir %{%{pythons}_sitelib}
```

This re-expands to the right per-flavor path (`%{python311_sitelib}`, `%{python312_sitelib}`, …).
The generic `%python_sitelib` only resolves to the _primary_ Python flavor.

## Conditional builds

### Fallback when `%{pythons}` is undefined

Older distributions (`<=` SLE 15 SP2 and all SLE 12) lack the `%{pythons}` macro. Provide a
fallback:

```spec
%if !0%{?pythons:1}
%define pythons python3
%endif
```

### Enable features by distro version

```spec
# Build Sphinx docs only on Leap 15-SP3+, Tumbleweed, Factory
%define build_docs 1
%if 0%{?suse_version} < 150300
%define build_docs 0
%endif
```

### Distro/arch conditionals

OBS (or your build system) feeds the right macros automatically for each target:

```spec
%if 0%{?sle_version}
# SLE-specific logic
%endif

%if 0%{?is_opensuse}
# openSUSE-specific logic
%endif
```

Keep conditionals minimal — the build system already handles the target matrix for you.

## Obsolete tags

### `BuildRoot:` — remove it

The `BuildRoot:` tag is **obsolete** since RPM >= 4.6.0. Modern RPM ignores it entirely, and OBS
always invokes `rpmbuild` with its own `--buildroot` argument.

```spec
# DELETE this line — it has no effect:
BuildRoot:     %{_tmppath}/%{name}-%{version}-build
```

Why it's safe to remove:

- RPM spec format docs: "`BuildRoot` is obsolete and unused in rpm >= 4.6.0"
- SLES 12+ Administration Guide: "the `BuildRoot` directive is deprecated since SLE 12"
- OBS builds always pass `--buildroot` on the command line, overriding any spec-level value
- Fedora 18+ and all current openSUSE releases do not require or honor it

Continue using `%{buildroot}` in your `%install` section — that variable is still set by RPM's
`--buildroot` option.

### `Group:` — also obsolete

Like `BuildRoot:`, the `Group:` tag is deprecated in Fedora 18+ and modern openSUSE. Safe to remove
from new packages.

## See also

- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/) — upstream spec file reference.
- [Fedora RPM Macros](https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/)
- [openSUSE Specfile guidelines](https://en.opensuse.org/openSUSE:Specfile_guidelines)
- [`../../tools/osc-obs/`](../../../tools/osc-obs/README.md) — running spec files through the Open
  Build Service with `osc`.
