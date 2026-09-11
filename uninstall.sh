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
launchctl unload "$PLIST_DEST" >/dev/null 2>&1 || true
rm -f "$PLIST_DEST"
echo "Removed launchd job."

# 2. Remove the runner script.
rm -f "$SCRIPT_DEST"
echo "Removed runner script."

# 3. Remove the logs.
if [ -d "$LOG_DIR" ]; then
  rm -rf "$LOG_DIR"
  echo "Removed logs at $LOG_DIR"
else
  echo "No logs found (nothing to remove)."
fi

# 4. Cancel the scheduled wake, if one was set up. This step needs sudo,
#    so macOS will ask for your password here -- that's expected.
echo
echo "Cancelling any scheduled wake (needs your password)..."
sudo pmset repeat cancel >/dev/null 2>&1 || true
echo "Wake schedule cancelled (or none was set)."

# 5. Remove the passwordless-sudo rule, if it exists. Also needs sudo.
if [ -f "$SUDOERS_FILE" ]; then
  sudo rm -f "$SUDOERS_FILE"
  echo "Removed passwordless-sudo rule at $SUDOERS_FILE"
else
  echo "No passwordless-sudo rule found (nothing to remove)."
fi

echo
echo "-------------------------------------------------------------"
echo "Done. busy-mole is fully removed: no scheduled job, no logs,"
echo "no wake schedule, no sudo rule."
echo
echo "Mole ('mo') itself was never touched by this -- it's still"
echo "installed and works normally if you run it by hand."
echo "-------------------------------------------------------------"
