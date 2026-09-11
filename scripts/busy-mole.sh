#!/bin/bash
# busy-mole: runs Mole's clean + optimize commands unattended.
#
# The log directory is deliberately NOT under ~/Library/Logs — Mole's own
# `mo clean` scans and clears folders under ~/Library/Logs as part of its
# normal cleanup, which means a log file kept there can get swept away by
# the very tool this script is running. ~/.local/state is outside Mole's
# cleanup scope.

set -uo pipefail  # deliberately not -e: one failing step shouldn't hide the other's output

LOG_DIR="$HOME/.local/state/busy-mole"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).log"

# launchd jobs start with a minimal PATH, so spell out where `mo` is most
# likely installed (Homebrew on Apple Silicon, Homebrew on Intel, or a
# user-local bin folder).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

MO_BIN="$(command -v mo || true)"

{
  echo "=== busy-mole run started: $(date) ==="

  if [ -z "$MO_BIN" ]; then
    echo "ERROR: could not find the 'mo' command on PATH ($PATH)."
    echo "Is Mole installed? https://github.com/tw93/mole"
    exit 1
  fi
  echo "Using mo at: $MO_BIN"

  echo "--- mo clean ---"
  yes | "$MO_BIN" clean
  clean_status=${PIPESTATUS[1]}
  echo "(mo clean exit status: $clean_status)"

  echo "--- mo optimize ---"
  yes | "$MO_BIN" optimize
  optimize_status=${PIPESTATUS[1]}
  echo "(mo optimize exit status: $optimize_status)"

  echo "=== busy-mole run finished: $(date) ==="
} >> "$LOG_FILE" 2>&1
block_status=$?

# Keep only the most recent 20 run logs so this folder doesn't grow forever.
ls -1t "$LOG_DIR"/2*.log 2>/dev/null | tail -n +21 | xargs -r rm --

exit $block_status
