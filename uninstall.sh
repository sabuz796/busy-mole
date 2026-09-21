#!/bin/bash
set -uo pipefail

PLIST_DEST="$HOME/Library/LaunchAgents/com.busy-mole.weekly.plist"
SCRIPT_DEST="$HOME/.local/bin/busy-mole.sh"
LOG_DIR="$HOME/.local/state/busy-mole"
SUDOERS_FILE="/etc/sudoers.d/busy-mole"

echo "== busy-mole uninstaller =="
echo "This removes everything busy-mole created. Mole itself ('mo') is never touched."
echo

# 1. Stop and remove the scheduled job.
#    bootout is the modern replacement for the deprecated `launchctl unload`.
launchctl bootout "gui/$(id -u)" "$PLIST_DEST" >/dev/null 2>&1 || true
rm -f "$PLIST_DEST"
echo "Removed launchd job."

# 2. Remove the runner script and the notification icon.
rm -f "$SCRIPT_DEST"
rm -rf "$HOME/.local/share/busy-mole"
echo "Removed runner script (and notification icon, if present)."

# 3. Remove the logs.
if [ -d "$LOG_DIR" ]; then
  rm -rf "$LOG_DIR"
  echo "Removed logs at $LOG_DIR"
else
  echo "No logs found (nothing to remove)."
fi

# 4. Cancel any repeating wake schedule (README Step 6), if one is set.
#    pmset has no "remove one entry" command — `repeat cancel` clears ALL
#    repeating power events — so show what exists and ask before cancelling.
#    Only runs (and asks for sudo) when a schedule is actually present.
WAKE_LEFT=0
if pmset -g sched 2>/dev/null | grep -qi 'wakeorpoweron'; then
  echo
  echo "A repeating wake/power-on schedule is set on this Mac:"
  pmset -g sched | grep -i 'wakeorpoweron' | sed 's/^/  /'
  echo
  echo "pmset can only cancel ALL repeating power schedules at once"
  echo "(including any unrelated ones you may have set for other reasons)."
  printf "Cancel all repeating power schedules? [y/N] "
  read -r answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    sudo pmset repeat cancel
    echo "Repeating power schedules cancelled."
  else
    echo "Left the wake schedule in place."
    WAKE_LEFT=1
  fi
else
  echo "No repeating wake schedule found (nothing to cancel)."
fi

# 5. Remove the passwordless-sudo rule, if it exists. Also needs sudo.
if [ -f "$SUDOERS_FILE" ]; then
  sudo rm -f "$SUDOERS_FILE"
  echo "Removed passwordless-sudo rule at $SUDOERS_FILE"
else
  echo "No passwordless-sudo rule found (nothing to remove)."
fi

echo
echo "-------------------------------------------------------------"
echo "Done. busy-mole is removed: the scheduled job, runner script,"
echo "and logs are gone."
if [ "${WAKE_LEFT:-0}" = "1" ]; then
  echo
  echo "Note: you chose to keep the repeating wake schedule. To remove"
  echo "it later: sudo pmset repeat cancel"
fi
echo
echo "Mole ('mo') itself was never touched by this -- it's still"
echo "installed and works normally if you run it by hand."
echo "-------------------------------------------------------------"
