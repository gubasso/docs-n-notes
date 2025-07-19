# Choose NTP Clients on Void Linux


## Summary

Among the four NTP implementations available on Void Linux—ISC-ntpd, OpenNTPD, Chrony, and ntpd-rs—**Chrony** emerges as the de facto choice for users seeking a reliable, low-maintenance time synchronizer. Although Void Linux does not publish client-specific popularity metrics, Chrony’s fast convergence, high accuracy under varying network conditions, and widespread adoption as the default NTP client in many major distributions strongly suggest it is the most used by the Void community ([docs.voidlinux.org][1], [octothorn.com][2]).

## Available NTP Clients on Void Linux

### ISC-ntpd

The official reference implementation of the Network Time Protocol, ISC-ntpd delivers comprehensive feature support—including broadcast and multicast modes—but typically requires more extensive configuration and ongoing maintenance to secure and optimize its operation ([docs.voidlinux.org][1]).

### OpenNTPD

OpenNTPD focuses on lean, secure time synchronization with minimal configuration. It “just works” for the majority of straightforward use cases, though it offers fewer advanced tuning options and slightly lower precision compared to Chrony and ISC-ntpd ([docs.voidlinux.org][1]).

### Chrony

Designed for fast synchronization and robust performance in environments with intermittent connectivity (e.g., laptops switching networks), Chrony achieves rapid convergence to the correct time and maintains high accuracy with minimal user tuning required ([docs.voidlinux.org][1], [pimylifeup.com][3]).

### ntpd-rs

A modern Rust-based implementation supporting Network Time Security (NTS), ntpd-rs is full-featured but still maturing; it may require additional troubleshooting and lacks the battle-testing of the other three daemons ([docs.voidlinux.org][1]).

## Community Adoption and Recommendation

* **Wider Linux Ecosystem:** Chrony has replaced ISC-ntpd as the default NTP client in many leading distributions—including RHEL and its derivatives—due to its superior speed and ease of maintenance ([octothorn.com][2], [howtouselinux.com][4]).
* **Void Documentation:** Void’s own Handbook lists all four daemons neutrally, but community discussion in the Void Linux docs GitHub (issue #123) highlights Chrony’s straightforward integration and minimal configuration, reinforcing its reputation for low upkeep ([github.com][5]).

## Which One to Choose

* **Chrony:** Best overall balance of speed, accuracy, and “set-and-forget” operation—highly recommended for most Void Linux users ([docs.voidlinux.org][1], [octothorn.com][2]).
* **OpenNTPD:** Opt for maximum simplicity and lowest resource use if you only need basic synchronization and can tolerate slightly less precision ([docs.voidlinux.org][1]).
* **ISC-ntpd:** Choose when you require advanced NTP features (e.g., broadcast/multicast) and are comfortable with more detailed configuration and periodic maintenance ([docs.voidlinux.org][1]).
* **ntpd-rs:** Consider if you want cutting-edge NTS support in a modern codebase and are willing to troubleshoot a less mature project ([docs.voidlinux.org][1]).

## Search Attempts

The following resources were reviewed but did not provide Void-specific usage statistics for NTP clients:

* **docs.voidlinux.org “Date and Time”** (Void Handbook section listing all four daemons) ([docs.voidlinux.org][1])
* **GitHub void-docs Issue #123** (basic date/time setup, no popularity data) ([github.com][5])
* **2DayGeek guide to Chrony** (general Linux tutorial) ([2daygeek.com][6])
* **HowToUseLinux.com – “Essential Guide to Using Chrony”** ([howtouselinux.com][4])
* **Red Hat blog on configuring Chrony** ([redhat.com][7])
* **PiMyLifeUp tutorial on Chrony** ([pimylifeup.com][3])
* **Anarcat blog “Switching from OpenNTPd to Chrony”** ([anarc.at][8])
* **OctoThorn overview of modern time synchronization** ([octothorn.com][2])

None of these provided direct insight into which daemon Void Linux users install or enable most frequently.

[1]: https://docs.voidlinux.org/config/date-time.html "Date and Time - Void Linux Handbook"
[2]: https://octothorn.com/site-management/modern-time-synchronization-for-linux/ "Time Synchronization Methods for Linux System Administrators: Switching ..."
[3]: https://pimylifeup.com/using-ntp-on-linux-with-chrony/ "Using NTP on Linux with Chrony - Pi My Life Up"
[4]: https://www.howtouselinux.com/post/using-chrony-for-ntp-on-linux "The Essential Guide to Using Chrony for NTP on Linux"
[5]: https://github.com/void-linux/void-docs/issues/123 "Section about date/time and ntp daemons · Issue #123 · void-linux/void ..."
[6]: https://www.2daygeek.com/configure-ntp-client-using-chrony-in-linux/ "How to install and configure Chrony as NTP client? - 2DayGeek"
[7]: https://www.redhat.com/en/blog/chrony-time-services-linux "How to configure chrony as an NTP client or server in Linux"
[8]: https://anarc.at/blog/2022-01-23-chrony/ "Switching from OpenNTPd to Chrony - anarcat"
