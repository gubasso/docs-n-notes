# Choosing CRON Deamon for Void

## Summary

Based on Void’s official handbook, community installation guides, and upstream project activity, **dcron** emerges as the de-facto cron implementation for Void Linux users seeking minimal maintenance and reliable behavior ([docs.voidlinux.org][1], [0ink.net][2]). While **Cronie** is actively maintained by the Fedora/RHEL community, it is less commonly chosen in Void setups ([github.com][3]). **Fcron** offers advanced scheduling features but has seen few updates since its 2016 release ([en.wikipedia.org][4]). Alternatives like **snooze** and **supercronic** address niche scenarios (e.g., simple one-off waits or crontab-only operation without a local MTA) but have smaller user bases and require custom runit service scripts ([voidlinux.org][5], [tech.0x5e00.com][6]). For broad community support, seamless runit integration, and low upkeep, **dcron** is the recommended choice.

---

## Available Cron Implementations on Void

Void’s official handbook documents multiple cron implementations available via XBPS:

* **cronie**: A modern fork of Vixie-cron with SELinux/PAM support.
* **dcron**: Dillon’s lightweight cron daemon compatible with standard `cron` syntax.
* **fcron**: An integrated cron+anacron replacement offering load-average and execution window controls.  ([docs.voidlinux.org][1])
* **snooze**: A simple wait-and-exec utility used with `snooze-hourly`, `snooze-daily`, etc. ([docs.voidlinux.org][1])
* **supercronic**: A Go-based crontab interpreter that runs without root/MTA and logs to stdout ([tech.0x5e00.com][6])

---

## Community Adoption and Usage

* **dcron**

  * Chosen in multiple Void install guides for its lightweight footprint and correct handling of missed runs during power-off periods ([0ink.net][2], [hadet.dev][7]).
* **Cronie**

  * Actively developed (latest release 1.7.2 in April 2024) but less frequently selected by Void users ([github.com][3]).
* **Fcron**

  * Implements anacron-style behavior natively, but its last stable release was in June 2016 (v3.2.1) with the next preview in December 2021 ([en.wikipedia.org][4]).
* **Snooze**

  * Stable since at least 2017 as part of Void’s `runit`-based scheduling alternatives, though adoption is limited to specific use cases ([voidlinux.org][5]).
* **Supercronic**

  * Provides crontab compatibility without requiring a local MTA, but remains a niche, manually installed solution ([tech.0x5e00.com][6]).

---

## Feature & Maintenance Comparison

| Implementation  | Upstream Activity & Stars                                                                | Maintenance Overhead                                      | Void Community Use                                           |
| --------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------ |
| **dcron**       | 127 ★ on GitHub; maintained C codebase ([github.com][8])                                 | Single small package, no extra deps; simple runit service | Widely recommended in guides ([0ink.net][2], [hadet.dev][7]) |
| **Cronie**      | 517 ★ on GitHub; frequent releases (v1.7.2, Apr 2024) ([github.com][3])                  | Requires optional PAM/SELinux, slightly larger footprint  | Supported but less chosen                                    |
| **Fcron**       | GPL-v2 project; last stable v3.2.1 (2016), preview v3.3.1 (2021) ([en.wikipedia.org][4]) | Rich feature set, more complex config                     | Rarely used                                                  |
| **Snooze**      | Part of Void’s `snooze` package since 2017 ([voidlinux.org][5])                          | Requires custom runit sv dir per job                      | Niche, script-based                                          |
| **Supercronic** | Go binary on GitHub; crontab-only runner ([tech.0x5e00.com][6])                          | Custom `/etc/sv` setup; no local MTA needed               | Niche                                                        |

---

## Recommendation

To minimize upkeep and align with established Void community practices, install **dcron**:

```bash
sudo xbps-install -Sy dcron
ln -s /etc/sv/dcron /var/service
```

This setup delivers full `cron` compatibility, robust handling of missed intervals, and seamless integration with Void’s `runit` service supervision—requiring virtually no extra configuration beyond enabling the service ([0ink.net][2], [hadet.dev][7]).

[1]: https://docs.voidlinux.org/config/cron.html "Cron - Void Linux Handbook"
[2]: https://0ink.net/posts/2019/2019-02-19-installing-void.html "Installing Void Linux - 0ink.net"
[3]: https://github.com/cronie-crond/cronie "GitHub - cronie-crond/cronie: Cronie cron daemon project"
[4]: https://en.wikipedia.org/wiki/Fcron "Fcron"
[5]: https://voidlinux.org/news/2017/12/snooze.html "The Advent of Void: Day 24: snooze - Void Linux"
[6]: https://tech.0x5e00.com/blog/2024/05/void-linux-cron-supercronic.html "Void Linuxで雑にcronしたい貴方に : supercronic - k5s.dmesg"
[7]: https://www.hadet.dev/ZFS-On-Linux-Experience/ "Switching to ZFS on Linux – Hadet – Earth Based System Administrator and Hobbyist"
[8]: https://github.com/dubiousjim/dcron "GitHub - dubiousjim/dcron: dillon's lightweight cron daemon"

---

## Summary

dcron is a highly **lightweight**, **self-contained** cron daemon that integrates anacron-like behavior into a minimal codebase, requiring only `/bin/sh` to run jobs—ideal for resource-constrained systems and setups without PAM/SELinux demands ([linuxbash.sh][1], [jimpryor.net][2]). In contrast, cronie is a **feature-rich**, **actively maintained** fork of Vixie-cron that offers **PAM authentication**, **SELinux support**, robust **syslog** integration, and native **anacron** tooling, at the cost of a larger footprint, extra dependencies, and more complex configuration ([linuxbash.sh][1], [wiki.archlinux.org][3]).

---

## Overview

### dcron

* **Origin & Maintenance**
  Developed by Matt Dillon and maintained by James Pryor, dcron targets simplicity and minimalism in a secure scheduler ([github.com][4]).
* **Core Philosophy**
  Avoids the complexity of separate anacron; integrates missed-job handling directly into the daemon ([jimpryor.net][2]).

### cronie

* **Origin & Maintenance**
  A Fedora/RHEL community project, cronie is actively developed (v1.7.2 released April 2024) and widely deployed on RHEL/CentOS systems ([github.com][5], [github.com][5]).
* **Core Philosophy**
  Builds on Vixie-cron’s proven foundation, extending it with modern security modules and logging capabilities.

---

## Pros of dcron

### 1. Lightweight Footprint

* dcron’s codebase is tiny (\~3 K LOC) and consumes minimal RAM/CPU, making it perfect for embedded or low-resource environments ([linuxbash.sh][1]).
* Unlike cronie, it has no PAM or SELinux dependencies, reducing install size and attack surface ([linuxbash.sh][1]).

### 2. Self-Contained Anacron Functionality

* Since v4.0, dcron includes built-in anacron-style features—no separate anacron binary needed ([jimpryor.net][2]).

### 3. Simplified Configuration & Dependencies

* Jobs run under `/bin/sh` without managing complex environment variables or shells ([packages.gentoo.org][6]).
* Configuration is limited to standard crontab syntax plus `@daily`/`@reboot` directives.

---

## Cons of dcron

### 1. Limited Security Integrations

* dcron does **not** support PAM authentication or SELinux confinement, making it unsuitable for environments requiring those security layers ([linuxbash.sh][1]).

### 2. Less Active Maintenance

* Upstream activity has slowed; the primary repository has seen few updates, and community patchsets (e.g., ptchinster’s fork) have emerged to fill the gap ([jimpryor.net][7]).

---

## Pros of cronie

### 1. Robust Security Integrations

* Native support for PAM modules and SELinux contexts ensures cron jobs adhere to system security policies ([linuxbash.sh][1]).

### 2. Native Anacron & Scheduled-jobs Directories

* Bundles anacron tool and automatically handles `/etc/cron.{hourly,daily,weekly,monthly}` jobs, ensuring periodic tasks run even after downtime ([wiki.archlinux.org][3]).

### 3. Active Upstream & Broad Adoption

* Versioned releases (e.g., 1.7.2 in April 2024) and inclusion as the default cron on RHEL/CentOS demonstrate its stability and community trust ([github.com][5]).

---

## Cons of cronie

### 1. Larger Footprint & Extra Dependencies

* Requires PAM libraries, SELinux policies, and optionally a mail transfer agent (MTA) for job output mailing, increasing disk and memory usage ([linuxbash.sh][1], [linuxbash.sh][1]).

### 2. Mailer Requirement or Silent Failure

* By default, cronie tries to email output via `sendmail`; if no MTA is installed, mail output is disabled without clear error ([wiki.archlinux.org][3]).

### 3. More Complex Configuration

* Integrating PAM and SELinux into cronjobs can demand additional context definitions and PAM stack adjustments, complicating maintenance ([docs.redhat.com][8]).

---

## Conclusion

* **Choose dcron** if you value a **minimal**, **fast**, and **self-contained** cron daemon with integrated anacron, especially on single-purpose or resource-limited systems.
* **Choose cronie** if your environment requires **advanced security**, **flexible logging**, and **native anacron/directories** support, and you’re comfortable with its additional dependencies and configuration complexity.

[1]: https://www.linuxbash.sh/post/default-cron-daemon-differences "Default Cron Daemon Differences - Linux Bash"
[2]: https://www.jimpryor.net/linux/dcron.html "Jim Pryor"
[3]: https://wiki.archlinux.org/title/Cron "cron - ArchWiki"
[4]: https://github.com/dubiousjim/dcron "GitHub - dubiousjim/dcron: dillon's lightweight cron daemon"
[5]: https://github.com/cronie-crond/cronie "GitHub - cronie-crond/cronie: Cronie cron daemon project"
[6]: https://packages.gentoo.org/packages/sys-process/dcron "sys-process/dcron – Gentoo Packages"
[7]: https://www.jimpryor.net/linux/dcron-README "James Pryor"
[8]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/6.7_technical_notes/package-cronie "7.33. cronie | 6.7 Technical Notes - Red Hat"

