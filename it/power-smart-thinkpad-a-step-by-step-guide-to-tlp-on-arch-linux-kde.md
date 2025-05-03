# Power‑Smart ThinkPad: A Step‑by‑Step Guide to TLP on Arch Linux + KDE

*(Lenovo ThinkPad • Arch Linux • KDE Plasma 6 — May 2025)*

---

## Why bother? Lithium‑ion science in one minute

* **Voltage stress & heat** – Every percent above ≈ 80 % SOC (state‑of‑charge) keeps the cathode at higher voltage, accelerating growth of passive films that rob capacity.([thedroidguy.com][1], [Battery University][2])
* **Cycle depth** – Jumping between 0 % and 100 % counts as a “full” cycle. Partial 40‑80 % top‑ups can practically **double usable cycles**.([global-batteries.com][3], [Redway Tech][4])
* **Storage health** – Storing a packed laptop for weeks at 95‑100 % bakes chemistry and may swell cells; 40‑60 % is gentler.([stablepsu.com][5])

Keeping charge oscillating between sensible limits (= **start @ ≈ 40 %, stop @ ≈ 80 %**) is therefore the single easiest way to add years to a ThinkPad pack.

## Why TLP beats KDE’s native power applet

|             | KDE Power Management                                                  | **TLP**                                                                                                                                                                       |
| ----------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Surface     | Brightness, suspend timers, lid actions                               | **Deep kernel‑level tuning**: CPU/PCI/AHCI/USB autosuspend, Wi‑Fi Tx‑power, audio runtime‑PM, disk‑cache flushing, plus **vendor battery thresholds** (ThinkPad, Dell, ASUS…) |
| Scope       | Session‑only (Plasma user service); relies on *power‑profiles‑daemon* | System‑wide service; runs even on TTY/Wayland/GDM; no GUI needed                                                                                                              |
| Granularity | Three generic profiles (Performance/Balanced/Power Save)              | \~100 tunables; per‑AC and per‑battery presets; CLI automation                                                                                                                |
| Conflicts   | Co‑exists, but can be overridden by systemd service changes           | **Will override** power‑profiles‑daemon—mask it for clarity                                                                                                                   |

Result: keep KDE’s GUI for screen dimming, but delegate heavy lifting to TLP for **measurably longer battery runtime & finer control**.([wiki.archlinux.org][6], [Arch Linux Forums][7])

## Install & enable TLP on Arch Linux

```bash
# Packages
sudo pacman -S tlp tlp-rdw \
             smartmontools # optional, for tlp-stat S.M.A.R.T.

# Enable services
sudo systemctl enable tlp.service tlp-sleep.service

# Avoid rfkill & KDE’s power‑profiles conflicts
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
sudo systemctl mask power-profiles-daemon.service

# Start now (no reboot needed)
sudo tlp start
```

TLP ships with sane defaults; the tweaks below build on them.([2daygeek.com][8])

## Optional GUI: TLP UI (GTK)

```bash
# AUR helper example (replace yay with paru/pikaur…)
yay -S tlpui
```

Launch with `tlpui`; it renders all parameters in friendly tabs and writes drop‑ins under `/etc/tlp.d/`. Note that recent KDE 6 updates required TLPUI ≥ 1.6.4.([aur.archlinux.org][13])

## Set healthy charge thresholds (ThinkPad‑only)

1. **Check support**

   ```bash
   sudo tlp-stat -b
   # Look for "tpacpi-bat" or "Vendor specific thresholds: supported"
   ```
2. **Create a drop‑in file**

   ```bash
   sudo nano /etc/tlp.d/90-thinkpad-battery.conf
   ```

   ```ini
   # Healthy 40‑80 rule
   START_CHARGE_THRESH_BAT0=40
   STOP_CHARGE_THRESH_BAT0=80
   ```

   *Dual batteries*? Add `*_BAT1=` lines.
3. **Apply immediately**

   ```bash
   sudo tlp setcharge   # shows current thresholds
   sudo tlp start
   ```

These limits keep the pack in its comfort zone while on AC — maximizing cycle life.([linrunner.de][9])

## Restore thresholds on battery (RESTORE\_THRESHOLDS\_ON\_BAT)

TLP can automatically reapply vendor‑specified charge thresholds when switching to battery power. By enabling `RESTORE_THRESHOLDS_ON_BAT`, you ensure that your healthy 40‑80 % charge limits remain in effect even after unplugging. Add this to your `/etc/tlp.d/90-thinkpad-battery.conf`:

```ini
# Reapply thresholds on battery
RESTORE_THRESHOLDS_ON_BAT0=1
# For dual batteries, also set RESTORE_THRESHOLDS_ON_BAT1=1
```

**Why set it up?**

* **Consistency**: Guarantees your thresholds persist across power states, preventing unintentional full charges.
* **Battery health**: Maintains the intended cycle depth rules regardless of AC transitions, further extending pack longevity.

## Performance profiles: AC ≠ battery

Edit `/etc/tlp.d/95-performance.conf` (new file):

```ini
# Full steam on the charger
CPU_ENERGY_PERF_POLICY_ON_AC=performance
PLATFORM_PROFILE_ON_AC=performance      # modern Lenovo firmware
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_BOOST_ON_AC=1                       # allow turbo

# Sips when unplugged
CPU_ENERGY_PERF_POLICY_ON_AC=balance_power
PLATFORM_PROFILE_ON_BAT=low-power
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_BOOST_ON_BAT=0
```

Re‑apply: `sudo tlp start`
These two pages describe all profile keywords and additional knobs.([linrunner.de][10], [linrunner.de][11])

## Heading out? Force a one‑off **100 %** top‑up

Need maximum runtime tomorrow?

```bash
sudo tlp fullcharge         # quickly lift to vendor preset (≈96‑100 %)
# OR charge only once to your stop threshold:
sudo tlp chargeonce
```

The original 40‑80 % rule is restored automatically on next boot, so you *won’t* forget to return to healthy limits.([linrunner.de][9], [man.archlinux.org][12])

## Wrap‑up & best‑practice cheat‑sheet

* **Daily desk use:** stay plugged, let thresholds hold battery at 40‑80 %.
* **Travel day:** run `tlp fullcharge`, shut lid only when LED hits 100 %.
* **Quarterly health check:** `sudo tlp-stat -b` for wear level (%), consider `tlp recalibrate` if reported capacity drifts.
* **Don’t mix tools:** if TLP rules your system, leave KDE’s battery plugin strictly for display & suspend timers.

Set once → forget → enjoy **quiet fans, cooler palm‑rest, and batteries that age gracefully**. Happy hacking!

[1]: https://thedroidguy.com/does-limiting-your-battery-to-80-really-prolong-your-battery-life-1259579?utm_source=chatgpt.com "Does Limiting Your Battery to 80% Really Prolong Your Battery Life?"
[2]: https://batteryuniversity.com/article/bu-808-how-to-prolong-lithium-based-batteries?utm_source=chatgpt.com "BU-808: How to Prolong Lithium-based Batteries - Battery University"
[3]: https://www.global-batteries.com/understanding-the-40-80-rule-for-batteries-maximizing-longevity/?utm_source=chatgpt.com "Understanding the 40-80 Rule for Batteries: Maximizing Longevity"
[4]: https://www.redway-tech.com/what-is-the-40-80-rule-for-lithium-batteries/?utm_source=chatgpt.com "What is the 40-80 Rule for Lithium Batteries? | Redway Tech"
[5]: https://www.stablepsu.com/lithium-ion-battery-charging-myths/?utm_source=chatgpt.com "Debunking Lithium-Ion Battery Charging Myths: Best Practices for ..."
[6]: https://wiki.archlinux.org/title/TLP?utm_source=chatgpt.com "TLP - ArchWiki"
[7]: https://bbs.archlinux.org/viewtopic.php?id=132198&utm_source=chatgpt.com "[SOLVED] Laptop-mode vs KDE Power Manager - Arch Linux Forums"
[8]: https://www.2daygeek.com/tlp-increase-optimize-linux-laptop-battery-life/?utm_source=chatgpt.com "TLP - An Advanced Power Management Tool That Improve Battery ... - 2DayGeek"
[9]: https://linrunner.de/tlp/usage/tlp.html?utm_source=chatgpt.com "tlp — TLP 1.8.0 documentation - linrunner.de"
[10]: https://linrunner.de/tlp/settings/platform.html?utm_source=chatgpt.com "Platform — TLP 1.8.0 documentation"
[11]: https://linrunner.de/tlp/support/optimizing.html?utm_source=chatgpt.com "Optimizing Guide — TLP 1.8.0 documentation"
[12]: https://man.archlinux.org/man/tlp.8.en?utm_source=chatgpt.com "tlp(8) - Arch manual pages"
[13]: https://aur.archlinux.org/packages/tlpui?utm_source=chatgpt.com "AUR (en) - tlpui"
