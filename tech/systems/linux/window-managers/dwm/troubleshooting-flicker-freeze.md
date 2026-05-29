# Troubleshooting: Flicker, Freeze, or Crash-to-Login Under Heavy Terminal Output

Example stack: Arch Linux, `dwm`, `kitty`, `picom`, HiDPI, and Intel + NVIDIA hybrid graphics.

## Diagnostics collector

Use a standardized diagnostics collector for post-crash evidence capture. In a local setup, keep the
collector close to the system notes or dotfiles that describe the affected stack.

Do not manually run ad-hoc command sets first if a local collector already exists.

## How to use (after a crash or severe flicker episode)

Run your local collector. For example:

```text
path/to/dwm-flicker-crash-report.sh
```

The script will:

1. Print a sectioned report to stdout (paste-friendly)
2. Automatically save the same report to a timestamped file (default
   `/tmp/dwm-flicker-crash-report-*.txt`)
3. Collect boot-scoped journal, kernel GPU faults, Xorg logs, coredumps, process/context snapshot,
   and key config values

If needed, choose custom output path:

```bash
REPORT_OUT="$HOME/dwm-crash-report.txt" path/to/dwm-flicker-crash-report.sh
```

## What to share for analysis

1. Paste the full script output
2. If too large, paste the saved report file path and its contents

## Crash classification matrix

| Evidence pattern                          | Classification                                             | Primary lane                  |
| ----------------------------------------- | ---------------------------------------------------------- | ----------------------------- |
| `NVRM: Xid` / GPU reset / DRM hang        | Driver or kernel GPU fault                                 | NVIDIA + kernel lane          |
| `Xorg` SIGSEGV/backtrace, no `Xid`        | X server or module/client interaction crash                | Xorg + compositor/client lane |
| No crash evidence, only visual corruption | Rendering saturation/state corruption without server crash | picom/kitty tuning lane       |

## Worked example: recurrent Xorg SIGABRT — no Xid, Intel/Mesa renderer

**Pattern:** repeated coredumps with an identical stack. No NVIDIA Xid or DRM hang/reset. Active GL
renderer is Mesa Intel Arc Graphics (MTL) via iris.

**Crash path (from `coredumpctl info` backtrace):**

```text
modesetting_drv.so +0x9cf9        #7  BlockHandler callback (crash site)
modesetting_drv.so +0x10b9b       #8  DDX internal call
 → BlockHandler → WaitForSomething → FatalError → OsAbort
```

Other threads at crash time: Mesa gallium workers in `pthread_cond_wait` — idle, not faulting.

**Interpretation:** The crash site is inside `modesetting_drv.so` (Intel Meteor Lake DDX), not picom
directly. This is a compositor/client interaction crash, not a GPU driver fault. picom is an
aggravating factor — its GLX backend + `use-damage=true` increases Damage event rate, which drives
more `BlockHandler` calls into the modesetting driver where the fault occurs.

**Baseline status:** After a complete `coredumpctl info` backtrace is captured via the standardized
collector, the crash signature is locked — no need to re-prove the same stack.

## Isolation experiments

Each step is a **runtime-only experiment** — generate temp configs under `/tmp`, do not edit
persistent configuration. One isolated condition per session, same stress workload each time. Run
the crash report collector after each session (crash or not).

Ordered by mitigation speed (fast first):

1. **No compositor** — `pkill picom` → 30 min heavy kitty output → run collector
   - If stable: compositor path confirmed as trigger
2. **picom xrender fallback** — `picom --config /tmp/picom-test.conf` with `backend = "xrender"` +
   `vsync = true` → same workload → collector
   - If stable: treat as temporary mitigation, stop here
3. **picom GLX no damage** — temp config with `use-damage = false` → workload → collector
   - Tests whether damage tracking specifically triggers the modesetting fault
4. **picom GLX no sync fence** — temp config with `xrender-sync-fence = false` → workload →
   collector
5. **kitty software render** — `LIBGL_ALWAYS_SOFTWARE=1 kitty` (only if crash persists with picom
   stopped)
6. **kitty Mesa GLX** — `__GLX_VENDOR_LIBRARY_NAME=mesa kitty` (only if still inconclusive)

`dwm`-level experiments (`dirty_bar`, `XSync`/`XFlush`, `resizehints`) are **out of scope** until
compositor/terminal path is ruled out.

## Acceptance criteria

1. 30+ minutes of heavy streaming output in kitty splits with no escalating flicker
2. No session drop to login during stress run
3. No new `Xid`, DRM hang/reset, or `Xorg` segfault evidence in collected report

## Crash log

| Phase             | Evidence                          | Notes                                                                      |
| ----------------- | --------------------------------- | -------------------------------------------------------------------------- |
| Initial captures  | journal `OsAbort` entries         | Abbreviated stacks only, no full backtrace                                 |
| Confirmed capture | Full `coredumpctl info` backtrace | `modesetting_drv.so` frames #7-#8 confirmed; collector captured full trace |

## References (primary)

- [picom(1) man page](https://man.archlinux.org/man/picom.1.en)
- [kitty configuration reference](https://sw.kovidgoyal.net/kitty/conf/)
- [Xorg(1) manual](https://www.x.org/releases/X11R7.5/doc/man/man1/Xorg.1.html)
- [coredumpctl(1) manual](https://man.archlinux.org/man/coredumpctl.1.en)
- [journalctl/systemd journal manual](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html)
- [NVIDIA Xid error documentation](https://docs.nvidia.com/deploy/xid-errors/index.html)
