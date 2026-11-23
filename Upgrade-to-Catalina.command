#!/bin/bash
# Upgrade-to-Catalina.command — Distro one-click upgrade, MacBookAir5,2 only
# Target: macOS Catalina 10.15.7 (official Apple ceiling for MacBookAir5,2)
# Installs to a NEW APFS volume "Catalina". Never overwrites High Sierra in v1.
# bash 3.2 compatible (stock macOS). First run = dry run; type ARM to proceed.
set -u
STATE_DIR="$HOME/Library/Logs/AcademyCatalinaUpgrade"
STATE="$STATE_DIR/state.txt"
LOG="$STATE_DIR/upgrade.log"
TARGET_VERSION="10.15.7"
TARGET_VOLUME="Catalina"
EXPECTED_MODEL="MacBookAir5,2"
MIN_FREE_GB=40
mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG") 2>&1
echo "=== Academy Distro One-Click Upgrade -> macOS Catalina $TARGET_VERSION ==="
echo "Date: $(date)  Log: $LOG"

fail() { echo "STOP: $1"; echo "state=STOPPED reason=$1" >> "$STATE"; exit 1; }

# --- Inventory ---
MODEL=$(sysctl -n hw.model 2>/dev/null || echo unknown)
RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
RAM_GB=$(( RAM_BYTES / 1073741824 ))
OS_VER=$(sw_vers -productVersion 2>/dev/null || echo unknown)
echo "Model: $MODEL | RAM: ${RAM_GB} GB | Current OS: $OS_VER"
[ "$MODEL" = "$EXPECTED_MODEL" ] || fail "Model is $MODEL, this package is built only for $EXPECTED_MODEL (MacBook Air 13-inch, Mid 2012)."
[ "$RAM_GB" -ge 4 ] || fail "RAM ${RAM_GB} GB < Catalina minimum 4 GB."
case "$OS_VER" in 10.13.*) : ;; *) fail "Expected starting OS 10.13.x High Sierra, found $OS_VER." ;; esac

# --- Gates ---
# AC power
if pmset -g batt 2>/dev/null | grep -q "AC Power"; then echo "Gate AC: PASS"; else fail "Not on AC power."; fi
# Boot filesystem must be APFS
BOOT_FS=$(diskutil info / 2>/dev/null | awk -F: '/File System Personality/ {gsub(/^ +/,"",$2); print $2}')
echo "Boot filesystem: $BOOT_FS"
case "$BOOT_FS" in *APFS*) echo "Gate APFS: PASS" ;; *) fail "Boot volume is not APFS ($BOOT_FS)." ;; esac
# Free space in APFS container
FREE_KB=$(df -k / | tail -1 | awk '{print $4}')
FREE_GB=$(( FREE_KB / 1048576 ))
echo "Free space: ${FREE_GB} GB (need >= ${MIN_FREE_GB} GB for dual-volume install)"
[ "$FREE_GB" -ge "$MIN_FREE_GB" ] || fail "Free space ${FREE_GB} GB < ${MIN_FREE_GB} GB. Dual-volume install refused; in-place upgrade is NOT auto-offered."
# Time Machine recency OR override handled at ARM prompt below
LAST_TM=$(tmutil latestbackup 2>/dev/null || echo "")
echo "Latest Time Machine backup: ${LAST_TM:-none found}"

# --- 32-bit app warning (Catalina is 64-bit only) ---
echo "--- 32-bit apps that will NOT run on Catalina ---"
system_profiler SPApplicationsDataType 2>/dev/null | awk '/^    [^ ]/ { name=$0; sub(/^ +/,"",name); sub(/:$/,"",name) } /Kind: 32-Bit/ { print "  - " name }' | head -50 || echo "(inventory unavailable — check manually)"
echo "--- end 32-bit list ---"

# --- Dry run / ARM ---
# No bypass: every invocation passes the ARM confirmation and the backup gate.
# (The former --armed shortcut was removed 2026-11-23 — it skipped both gates.)
echo "DRY RUN complete. No changes made."
echo "Type ARM to fetch the official Catalina installer and install to new volume '$TARGET_VOLUME'."
printf "Type ARM to proceed, anything else to stop: "
read -r ANSWER
[ "$ANSWER" = "ARM" ] || { echo "Not armed. Exiting clean."; exit 0; }
if [ -z "$LAST_TM" ]; then
  printf "No Time Machine backup found. Type OVERRIDE to proceed without one: "
  read -r OVERRIDE
  [ "$OVERRIDE" = "OVERRIDE" ] || fail "No backup and no override."
fi

# --- Fetch official installer (Apple CDN via installinstallmacos.py) ---
WORK="$HOME/Downloads/AcademyCatalinaUpgrade"
mkdir -p "$WORK"; cd "$WORK" || fail "Cannot enter $WORK"
INSTALLER_APP="/Applications/Install macOS Catalina.app"
if [ ! -d "$INSTALLER_APP" ]; then
  echo "Fetching Install macOS Catalina $TARGET_VERSION from Apple via installinstallmacos.py ..."
  # installinstallmacos.py: https://github.com/munki/macadmin-scripts — coordinator pins + hashes this file in the Distro build; runtime refuses an unpinned copy.
  # The pinned copy ships beside this launcher (package dir); stage it into the workdir.
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SCRIPT_DIR/installinstallmacos.py" ]; then cp "$SCRIPT_DIR/installinstallmacos.py" ./installinstallmacos.py; fi
  [ -f ./installinstallmacos.py ] || fail "installinstallmacos.py not bundled. Distro build must ship the pinned, hash-verified copy beside this launcher."
  # Pinned copy verification (PIN.md): munki/macadmin-scripts @ ae5d4a8a, Apache-2.0, (c) Greg Neagle
  PIN_SHA="4b06e394a2255cca5fea901c5000c9b7a24740e0e3127c952c3f93dff3ca8ebf"
  ACTUAL_SHA=$(shasum -a 256 ./installinstallmacos.py | awk '{print $1}')
  [ "$ACTUAL_SHA" = "$PIN_SHA" ] || fail "installinstallmacos.py SHA-256 mismatch (got $ACTUAL_SHA, pinned $PIN_SHA). Refusing to run an unpinned fetcher."
  echo "Gate fetcher-pin: PASS (SHA-256 matches PIN.md)"
  sudo python ./installinstallmacos.py --workdir "$WORK/build" --version "$TARGET_VERSION" || fail "Installer fetch failed."
  [ -d "$INSTALLER_APP" ] || fail "Installer app not present after fetch."
fi
echo "Verifying installer signature..."
codesign --verify --deep --strict "$INSTALLER_APP" || fail "Installer codesign verification FAILED."
spctl --assess --type execute "$INSTALLER_APP" || fail "Installer Gatekeeper assessment FAILED."
echo "state=INSTALLER_VERIFIED" >> "$STATE"

# --- Create target volume (never touches the High Sierra volume) ---
BOOT_DISK=$(diskutil info / | awk -F: '/Part of Whole/ {gsub(/^ +/,"",$2); print $2}')
CONTAINER=$(diskutil list "$BOOT_DISK" 2>/dev/null | awk '/APFS Container Scheme/ {print $NF}')
echo "APFS container: $CONTAINER"
if diskutil apfs list "$CONTAINER" 2>/dev/null | grep -q "Name:.*$TARGET_VOLUME"; then
  echo "Volume '$TARGET_VOLUME' already exists — resuming install stage."
else
  diskutil apfs addVolume "$CONTAINER" APFS "$TARGET_VOLUME" || fail "Could not create APFS volume $TARGET_VOLUME."
fi
echo "state=VOLUME_READY" >> "$STATE"

# --- Install to the new volume ---
echo "Installing Catalina to /Volumes/$TARGET_VOLUME (High Sierra volume untouched)..."
sudo "$INSTALLER_APP/Contents/Resources/startosinstall" \
  --agreetolicense --nointeraction --volume "/Volumes/$TARGET_VOLUME" \
  || fail "startosinstall failed — see $LOG. High Sierra volume is untouched; reboot holding Option to return to it."
echo "state=INSTALL_LAUNCHED" >> "$STATE"
echo "Install launched. On reboot into Catalina: run post-install verification (sw_vers = 10.15.7, TLS check) and report PASS/FAIL. Rollback: Option-boot -> High Sierra."
