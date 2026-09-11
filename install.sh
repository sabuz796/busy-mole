#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_LABEL="com.busy-mole.weekly"
PLIST_SRC="$REPO_DIR/launchd/com.busy-mole.weekly.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
SCRIPT_DEST="$HOME/.local/bin/busy-mole.sh"

echo "== busy-mole installer =="
echo

# launchd jobs start with a minimal PATH, so make sure Homebrew paths
# are available for the mo check (same paths the runner script uses).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# 1. Make sure Mole is actually installed first.
if ! command -v mo >/dev/null 2>&1; then
  echo "Couldn't find the 'mo' command on your PATH."
  echo "Install Mole first: https://github.com/tw93/mole"
  echo "  brew install mole"
  echo "  (or, on older macOS: curl -fsSL https://raw.githubusercontent.com/tw93/mole/main/install.sh | bash)"
  exit 1
fi
echo "Found Mole at: $(command -v mo)"

# 2. Put the runner script somewhere stable.
mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/scripts/busy-mole.sh" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
echo "Installed runner script -> $SCRIPT_DEST"

# 3. Fill in the plist template with real paths and drop it in LaunchAgents.
mkdir -p "$HOME/Library/LaunchAgents"
sed \
  -e "s#__SCRIPT_PATH__#$SCRIPT_DEST#g" \
  -e "s#__HOME__#$HOME#g" \
  "$PLIST_SRC" > "$PLIST_DEST"
echo "Wrote launchd job -> $PLIST_DEST"

mkdir -p "$HOME/.local/state/busy-mole"

# 4. Load it (unload first in case this is a re-run).
launchctl unload "$PLIST_DEST" >/dev/null 2>&1 || true
launchctl load "$PLIST_DEST"
echo "Loaded launchd job: $PLIST_LABEL"

echo
echo "-------------------------------------------------------------"
echo "Done. busy-mole will run 'mo clean' and 'mo optimize' every"
echo "Monday at 12:00 AM."
echo
echo "Logs land in: $HOME/.local/state/busy-mole/"
echo
echo "Two things worth doing next (see README for details):"
echo
echo "  1. Test it right now instead of waiting for Monday:"
echo "       bash \"$SCRIPT_DEST\""
echo "     Then check the newest file in $HOME/.local/state/busy-mole/"
echo
echo "  2. Make the Mac wake itself for the job in case it's asleep:"
echo "       sudo pmset repeat wakeorpoweron M 23:55:00"
echo "-------------------------------------------------------------"
