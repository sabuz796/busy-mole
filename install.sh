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

# 2b. Notification icon (optional — used only if terminal-notifier is installed).
if [ -f "$REPO_DIR/assets/icon.png" ]; then
  mkdir -p "$HOME/.local/share/busy-mole"
  cp "$REPO_DIR/assets/icon.png" "$HOME/.local/share/busy-mole/icon.png"
  echo "Installed notification icon -> $HOME/.local/share/busy-mole/icon.png"
fi

# 3. Fill in the plist template with real paths and drop it in LaunchAgents.
mkdir -p "$HOME/Library/LaunchAgents"

if [ ! -f "$PLIST_SRC" ]; then
  echo "ERROR: launchd template not found at $PLIST_SRC" >&2
  exit 1
fi

# Escape the characters that are special in a sed replacement string when
# '#' is used as the delimiter: '#' (would end the substitution), '&' (means
# "the matched text"), and '\' (the escape character).  '/' does NOT need
# escaping because '#' — not '/' — is the delimiter here.
sed_esc() {
  printf '%s' "$1" | sed -e 's/[#&\]/\\&/g'
}

plist_script="$(sed_esc "$SCRIPT_DEST")"
plist_home="$(sed_esc "$HOME")"

sed \
  -e "s#__SCRIPT_PATH__#$plist_script#g" \
  -e "s#__HOME__#$plist_home#g" \
  "$PLIST_SRC" > "$PLIST_DEST"

if ! plutil -lint "$PLIST_DEST" >/dev/null 2>&1; then
  echo "ERROR: wrote plist but it failed plutil validation:" >&2
  echo "  $PLIST_DEST" >&2
  rm -f "$PLIST_DEST"
  exit 1
fi

echo "Wrote launchd job -> $PLIST_DEST"


mkdir -p "$HOME/.local/state/busy-mole"

# 4. Load it (bootout first in case this is a re-run).
# bootstrap/bootout are the modern replacements for the deprecated
# `launchctl load` / `launchctl unload`.
UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM" "$PLIST_DEST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST_DEST"
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
echo "  1. Test it right now instead of waiting for Monday"
echo "     (you'll see it working live in this terminal):"
echo "       bash \"$SCRIPT_DEST\""
echo "     Then check the newest file in $HOME/.local/state/busy-mole/"
echo
echo "  2. Optional: run at midnight sharp even when the Mac is asleep"
echo "     (without this, the job simply runs when the Mac next wakes):"
echo "       sudo pmset repeat wakeorpoweron M 23:55:00"
echo "-------------------------------------------------------------"
