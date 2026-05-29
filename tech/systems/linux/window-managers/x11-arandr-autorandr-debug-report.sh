#!/usr/bin/env bash
#
# x11-arandr-autorandr-debug-report.sh
#
# Collect a paste-friendly report for X11 monitor issues involving xrandr,
# arandr, autorandr, docks, EDID, and hybrid-GPU display paths.
#
# Usage:
#   tech/systems/linux/window-managers/x11-arandr-autorandr-debug-report.sh
#   REPORT_OUT="$HOME/x11-monitor-report.txt" tech/systems/linux/window-managers/x11-arandr-autorandr-debug-report.sh
#

set -u
set -o pipefail

LOG_RE='xorg|xrandr|autorandr|arandr|drm|edid|displayport|thunderbolt|typec|usb4|nvidia|i915|xe'

hr() {
  printf '\n%s\n' "--------------------------------------------------------------------------------"
}

section() {
  hr
  printf '[SECTION] %s\n' "$1"
  hr
}

exists() {
  command -v "$1" >/dev/null 2>&1
}

run_cmd() {
  local title="$1"
  shift
  printf '\n[CMD] %s\n' "$title"
  printf '[RUN] %s\n\n' "$*"
  "$@"
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    printf '\n[WARN] command exited with code %d\n' "$rc"
  fi
}

run_sh() {
  local title="$1"
  local cmd="$2"
  printf '\n[CMD] %s\n' "$title"
  printf '[RUN] %s\n\n' "$cmd"
  bash -o pipefail -lc "$cmd"
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    printf '\n[WARN] command exited with code %d\n' "$rc"
  fi
}

show_file() {
  local file="$1"
  local lines="${2:-200}"
  if [[ -r "$file" ]]; then
    printf '\n[FILE] %s (tail -n %s)\n\n' "$file" "$lines"
    tail -n "$lines" "$file"
  else
    printf '\n[INFO] %s not readable (or not found)\n' "$file"
  fi
}

print_env_var() {
  local name="$1"
  local value="${!name-}"
  if [[ -n "$value" ]]; then
    printf '%s=%s\n' "$name" "$value"
  else
    printf '%s=(unset)\n' "$name"
  fi
}

collect_sysfs_connectors() {
  local status_file connector dir
  shopt -s nullglob
  for status_file in /sys/class/drm/card*-*/status; do
    dir="$(dirname "$status_file")"
    connector="$(basename "$dir")"
    printf '\n[CONNECTOR] %s\n' "$connector"
    printf 'status: %s\n' "$(cat "$status_file" 2>/dev/null || printf 'unreadable')"
    if [[ -r "$dir/enabled" ]]; then
      printf 'enabled: %s\n' "$(cat "$dir/enabled" 2>/dev/null || printf 'unreadable')"
    fi
    if [[ -r "$dir/modes" ]]; then
      printf 'modes:\n'
      sed 's/^/  - /' "$dir/modes"
    fi
    if [[ -r "$dir/edid" ]]; then
      printf 'edid: present\n'
    else
      printf 'edid: absent\n'
    fi
  done
  shopt -u nullglob
}

collect_edid_summaries() {
  local edid_file dir connector
  if ! exists edid-decode; then
    printf '[INFO] edid-decode not found; install it if EDID inspection is needed\n'
    return 0
  fi

  shopt -s nullglob
  for edid_file in /sys/class/drm/card*-*/edid; do
    dir="$(dirname "$edid_file")"
    connector="$(basename "$dir")"
    if [[ ! -r "$edid_file" ]]; then
      continue
    fi

    printf '\n[EDID] %s\n' "$connector"
    edid-decode "$edid_file" 2>/dev/null |
      grep -E 'Display Product Name|Display Product Serial Number|Manufacturer|Model|Preferred Detailed Timing|Native detailed mode|Detailed mode|Maximum image size' ||
      printf '[INFO] no compact EDID summary matched expected patterns\n'
  done
  shopt -u nullglob
}

collect_autorandr_files() {
  local base="$HOME/.config/autorandr"
  if [[ ! -d "$base" ]]; then
    printf '[INFO] %s not found\n' "$base"
    return 0
  fi

  run_sh "autorandr tree" "find \"$base\" -maxdepth 2 -mindepth 1 | sort"

  local file
  shopt -s nullglob
  for file in "$base"/predetect "$base"/postswitch "$base"/*/config "$base"/*/setup "$base"/*/postswitch; do
    if [[ -f "$file" ]]; then
      printf '\n[FILE] %s\n\n' "$file"
      sed -n '1,220p' "$file"
    fi
  done
  shopt -u nullglob
}

REPORT_OUT="${REPORT_OUT:-/tmp/x11-arandr-autorandr-debug-report-$(date +%Y%m%d-%H%M%S).txt}"
REPORT_DIR="$(dirname "$REPORT_OUT")"

mkdir -p "$REPORT_DIR"
exec > >(tee "$REPORT_OUT") 2>&1

section "Report Header"
printf 'Report generated: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Hostname: %s\n' "$(hostnamectl --static 2>/dev/null || hostname)"
printf 'Kernel: %s\n' "$(uname -a)"
printf 'User: %s\n' "$(id -un 2>/dev/null || printf '%s' "${USER:-unknown}")"
printf 'Script: %s\n' "tech/systems/linux/window-managers/x11-arandr-autorandr-debug-report.sh"
printf 'Report file: %s\n' "$REPORT_OUT"
printf 'Output mode: stdout + auto-save (tee)\n'

section "Session Context"
print_env_var DISPLAY
print_env_var XAUTHORITY
print_env_var XDG_SESSION_TYPE
print_env_var XDG_CURRENT_DESKTOP
print_env_var DESKTOP_SESSION
print_env_var WAYLAND_DISPLAY
print_env_var DBUS_SESSION_BUS_ADDRESS
run_sh "Uptime" "uptime -p 2>/dev/null; uptime"
run_sh "Relevant process snapshot" "ps -eo pid,comm,args --sort=comm | grep -E '[X]org|[X]wayland|[d]wm|[p]icom|[s]xhkd|[a]utorandr|[a]randr' || true"

section "Tool Availability And Versions"
run_sh "Tool paths" "command -v xrandr arandr autorandr edid-decode xset qdbus-qt5 qdbus6 boltctl glxinfo nvidia-smi lspci lsusb journalctl 2>/dev/null || true"
if exists xrandr; then
  run_cmd "xrandr version" xrandr --version
fi
if exists arandr; then
  run_cmd "arandr version" arandr --version
fi
if exists autorandr; then
  run_cmd "autorandr version" autorandr --version
fi
if exists pacman; then
  run_sh "Relevant Arch packages" "pacman -Q xorg-xrandr arandr autorandr xorg-server mesa mesa-utils edid-decode nvidia-open nvidia-utils nvidia-settings nvidia-prime linux 2>/dev/null || true"
fi

section "Graphics Stack Inventory"
if exists lspci; then
  run_sh "PCI graphics and Thunderbolt devices" "lspci -nnk | grep -A3 -E 'VGA compatible controller|3D controller|Display controller|Thunderbolt|USB controller' || true"
fi
run_sh "Loaded graphics modules" "lsmod | grep -E '^(nvidia|nvidia_drm|nvidia_modeset|nvidia_uvm|i915|xe|amdgpu|drm|drm_kms_helper)' || true"
if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
  run_sh "nvidia_drm modeset parameter" "cat /sys/module/nvidia_drm/parameters/modeset"
fi
if [[ -r /sys/module/nvidia_drm/parameters/fbdev ]]; then
  run_sh "nvidia_drm fbdev parameter" "cat /sys/module/nvidia_drm/parameters/fbdev"
fi
if exists glxinfo; then
  run_sh "glxinfo -B" "glxinfo -B 2>/dev/null || true"
fi
if exists nvidia-smi; then
  run_cmd "nvidia-smi -L" nvidia-smi -L
fi

section "Dock And USB Inventory"
if exists boltctl; then
  run_cmd "boltctl list" boltctl list
fi
if exists lsusb; then
  run_sh "lsusb" "lsusb"
fi

section "XRandR Snapshot"
if exists xrandr; then
  run_cmd "xrandr --query" xrandr --query
  run_cmd "xrandr --listmonitors" xrandr --listmonitors
  run_cmd "xrandr --listproviders" xrandr --listproviders
  run_cmd "xrandr --verbose --query" xrandr --verbose --query
else
  printf '[WARN] xrandr not found; this report is incomplete\n'
fi

section "DRM Sysfs Connector State"
collect_sysfs_connectors

section "EDID Summary"
collect_edid_summaries

section "autorandr State"
if exists autorandr; then
  run_cmd "autorandr --current" autorandr --current
  run_cmd "autorandr --detected" autorandr --detected
  run_cmd "autorandr --fingerprint" autorandr --fingerprint
else
  printf '[INFO] autorandr not installed\n'
fi
collect_autorandr_files

section "X11 Configuration Files"
show_file "$HOME/.xinitrc" 220
show_file "$HOME/.xprofile" 220
show_file "$HOME/.xsession" 220
show_file "$HOME/.xsessionrc" 220

section "Logs"
if exists journalctl; then
  run_sh "Current boot log matches" "journalctl -b --no-pager 2>/dev/null | grep -iE '$LOG_RE' | tail -n 400 || true"
  run_sh "Kernel log matches" "journalctl -k -b --no-pager 2>/dev/null | grep -iE '$LOG_RE' | tail -n 400 || true"
fi
if exists dmesg; then
  run_sh "dmesg matches" "dmesg -T 2>/dev/null | grep -iE '$LOG_RE' | tail -n 400 || true"
fi
show_file "$HOME/.local/share/xorg/Xorg.0.log" 240
show_file "/var/log/Xorg.0.log" 240

section "Quick Interpretation Hints"
cat <<'EOF'
- If xrandr shows an external connector as "connected" but it is missing from arandr, first try enabling it with:
  xrandr --output <OUTPUT> --auto
- If --auto lights the monitor but at the wrong resolution, inspect the preferred mode in xrandr --query and the EDID summary above.
- If autorandr matches the wrong profile, compare:
  autorandr --fingerprint
  ~/.config/autorandr/<profile>/setup
- If dock hotplug is racy, a small ~/.config/autorandr/predetect sleep can help.
- If xrandr --listproviders shows multiple providers, note which provider actually owns outputs and CRTCs.
EOF

section "How To Share This Report"
cat <<EOF
1. Reproduce the problem while inside the affected X11 session.
2. Run:
  tech/systems/linux/window-managers/x11-arandr-autorandr-debug-report.sh
3. Paste the full terminal output to the debugging helper.
4. If needed, share the saved file instead:
  $REPORT_OUT
EOF
