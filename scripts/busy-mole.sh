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

# Icon shown on notifications when terminal-notifier (optional) is installed.
ICON_FILE="$HOME/.local/share/busy-mole/icon.png"

# Post a macOS notification. $1 = message; pass "audible" as $2 to add a sound.
# Prefers terminal-notifier when installed (it supports the custom icon);
# falls back to built-in AppleScript notifications, which always show the
# Script Editor icon. A notification failure never breaks the run.
notify() {
  local msg="$1"
  if command -v terminal-notifier >/dev/null 2>&1; then
    local args=(-title "busy-mole" -message "$msg")
    [ -f "$ICON_FILE" ] && args+=(-contentImage "$ICON_FILE")
    [ "${2:-}" = "audible" ] && args+=(-sound Basso)
    terminal-notifier "${args[@]}" >/dev/null 2>&1 || true
  else
    local extra=""
    [ "${2:-}" = "audible" ] && extra=' sound name "Basso"'
    osascript -e "display notification \"$msg\" with title \"busy-mole\"$extra" >/dev/null 2>&1 || true
  fi
}

# launchd jobs start with a minimal PATH, so spell out where `mo` is most
# likely installed (Homebrew on Apple Silicon, Homebrew on Intel, or a
# user-local bin folder).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# Which mode to run in. Normally auto-detected: a terminal attached means a
# manual run (show output live, no notification); no terminal means the
# weekly launchd run (log to file, then notify). BUSY_MOLE_MODE overrides
# the detection so both modes can be tested without needing a real terminal.
MODE="${BUSY_MOLE_MODE:-}"
case "$MODE" in
  interactive | scheduled) ;;
  *)
    # Unset, or a typo — fall back to auto-detection.
    if [ -t 1 ]; then
      MODE=interactive
    else
      MODE=scheduled
    fi
    ;;
esac

MO_BIN="$(command -v mo || true)"

# Fail early, before opening the log redirect, so this error lands in
# launchd's stderr log (launchd.err.log) instead of a dated run log.
# Note: this early exit also skips the log-rotation step below — fine,
# since no new run log was created on this path.
if [ -z "$MO_BIN" ]; then
  echo "ERROR: could not find the 'mo' command on PATH ($PATH)." >&2
  echo "Is Mole installed? https://github.com/tw93/mole" >&2
  # Notify only on scheduled runs — a manual run shows this error already.
  if [ "$MODE" = "scheduled" ]; then
    notify "busy-mole could not find the mo command - is Mole still installed?" audible
  fi
  exit 1
fi

# stdin for each Mole command is /dev/null: that's what tells Mole it is
# unattended (it prints "Running in non-interactive mode" and skips prompts
# and sudo sections). Unlike a `yes |` pipe this can never hang — a pipe
# stays open if Mole ever leaves a background process holding it, which
# would stall this script forever after all visible output is done.
run_cleanup() {
  echo "=== busy-mole run started: $(date) ==="
  echo "Using mo at: $MO_BIN"
  echo "Disk free at start: $free_before"

  echo "--- mo clean ---"
  "$MO_BIN" clean < /dev/null
  clean_status=$?
  echo "(mo clean exit status: $clean_status)"

  echo "--- mo optimize ---"
  "$MO_BIN" optimize < /dev/null
  optimize_status=$?
  echo "(mo optimize exit status: $optimize_status)"

  free_after="$(df -h / | awk 'NR==2 {print $4}')"
  echo "Disk free at end:   $free_after"
  echo "=== busy-mole run finished: $(date) ==="
}

free_before="$(df -h / | awk 'NR==2 {print $4}')"
if [ "$MODE" = "interactive" ]; then
  # Manual run: show output live AND write the log. (Process substitution,
  # not a pipe — a pipe would subshell the function and lose its exit codes.)
  run_cleanup > >(tee "$LOG_FILE") 2>&1
  wait # let tee finish flushing the log before the script exits
else
  # Scheduled run (launchd): log to file only; notification comes at the end.
  run_cleanup >> "$LOG_FILE" 2>&1
fi

# If either step failed, report that as the script's exit status so launchd
# and any monitoring can tell that something went wrong. Otherwise 0.
block_status=0
if [ "$clean_status" -ne 0 ] 2>/dev/null; then
  block_status=$clean_status
fi
if [ "$optimize_status" -ne 0 ] 2>/dev/null; then
  # If both failed, prefer the optimize status (the later step).
  block_status=$optimize_status
fi

# Notifications are for the weekly scheduled runs — a manual run is watched
# live in the terminal, so it doesn't need one. Audible on failure (a broken
# automation must not hide), quiet on success.
if [ "$MODE" = "scheduled" ]; then
  if [ "$block_status" -ne 0 ]; then
    notify "A cleanup run failed (exit $block_status) - check the newest log in ~/.local/state/busy-mole" audible
  else
    notify "Weekly cleanup finished. Disk free: $free_before -> $free_after"
  fi
fi

# Keep only the most recent 20 run logs. Log names are timestamps, and a glob
# expands in lexical order — which for zero-padded names is also chronological
# — so the oldest entries are simply the first ones in the array.
run_logs=("$LOG_DIR"/2*.log)
if [ -f "${run_logs[0]}" ] && [ "${#run_logs[@]}" -gt 20 ]; then
  for ((i = 0; i <= ${#run_logs[@]} - 21; i++)); do
    rm -f "${run_logs[i]}"
  done
fi

# launchd stdout/stderr logs are not written by these runs (everything goes
# to the dated log above), but a failed `mo` lookup writes to stderr — keep
# those files from growing without bound.
launchd_logs=("$LOG_DIR"/launchd.out.log "$LOG_DIR"/launchd.err.log)
for lf in "${launchd_logs[@]}"; do
  if [ -f "$lf" ] && [ -s "$lf" ]; then
    mv "$lf" "$lf".1 2>/dev/null || true
  fi
done

exit $block_status

