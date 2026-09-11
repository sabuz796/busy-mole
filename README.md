# busy-mole 🐭

**The mole works while you sleep.**

*An unofficial helper that schedules [Mole](https://github.com/tw93/mole) — a free, open-source Mac cleanup tool by [tw93](https://github.com/tw93) — to run automatically every week. Not affiliated with or endorsed by the Mole project; all the actual cleaning is done by Mole itself, full credit to them.*

---

## Quick start

> **Prerequisite:** [Mole](https://github.com/tw93/mole) must be installed first (`brew install mole`, or see [Requirements](#-requirements) below).

```bash
# 1. Get the files (pick one)
git clone https://github.com/YOUR-USERNAME/busy-mole.git
cd busy-mole

# 2. Install
bash install.sh

# 3. Test it right now
bash ~/.local/bin/busy-mole.sh
```

That's it. busy-mole will run `mo clean` then `mo optimize` every Monday at midnight. Keep reading for details on what this deletes, how to set it up, and how to change the schedule.

---

## What does this delete?

This is the first question anyone asks, so here it is upfront.

**User-level cleanup (always runs):**
- App and system caches (safe to delete — macOS rebuilds them)
- Old log files
- Browser caches (not your bookmarks, history, or saved passwords)
- Developer tool caches (Xcode, Homebrew, npm, etc.)

**System-level cleanup (skipped by default):**
- System-level caches that need admin permission
- Mole detects it's running unattended and skips this step cleanly on its own — nothing hangs, nothing breaks

**What it does NOT touch:**
- Your documents, photos, music, or videos
- Browser bookmarks, history, or saved passwords
- Application settings or preferences
- Any data you created

Everything it deletes is rebuildable cache data. If you want to see exactly what Mole does before trusting it, run `mo clean` by hand first (Step 1 below).

---

## What it does

| Detail | Value |
|---|---|
| Runs | `mo clean` then `mo optimize`, in that order |
| Schedule | Every Monday, 12:00 AM |
| Scheduler | macOS's built-in launchd (the task scheduler that comes with your Mac) |
| Works locked? | Yes |
| Works asleep? | Yes, with one extra setup step (Step 6 below) |
| Cost | Free — no paid tools, no extra dependencies |

---

## Requirements

- macOS (Intel or Apple Silicon)
- [Mole](https://github.com/tw93/mole) must be installed first

**Installing Mole:**

On macOS 14+, the recommended way is with [Homebrew](https://brew.sh) (a free package manager for macOS — if you don't have it, visit [brew.sh](https://brew.sh) for install instructions):

```bash
brew install mole
```

On older macOS, or without Homebrew:

```bash
curl -fsSL https://raw.githubusercontent.com/tw93/mole/main/install.sh | bash
```

Check it worked:

```bash
mo --version
```

---

## Setup

Throughout this guide:
- **`~`** (tilde) means your home folder — e.g. `/Users/yourname`
- **`sudo`** means a command that needs your admin password
- **Terminal** is the app you type commands into (search for it with Spotlight)

### Step 1 — Watch it run once, by hand

```bash
mo clean
```

This automation will later auto-confirm anything Mole asks (it pipes "yes" to every prompt). Seeing what Mole actually does on your Mac, once, with your own eyes, is worth two minutes before handing it over to a schedule.

> **Tip:** If Mole asks you questions during this manual run, that's normal — you'll see the same prompts skipped in automated mode.

### Step 2 — Get the files

**Option A — if you have Git installed:**
```bash
git clone https://github.com/YOUR-USERNAME/busy-mole.git
cd busy-mole
```

**Option B — download the ZIP:**
1. Go to the busy-mole GitHub page
2. Click the green **Code** button → **Download ZIP**
3. Double-click the downloaded `.zip` file to unzip it
4. Open Terminal and type `cd ` (with a space), then drag the unzipped folder into the Terminal window and press Enter

### Step 3 — Install

```bash
bash install.sh
```

The installer will:
1. Check that Mole is installed
2. Copy the runner script to `~/.local/bin/busy-mole.sh` (a folder in your home directory)
3. Set up the weekly schedule using macOS's built-in task scheduler (launchd)
4. Load the schedule so it starts running

### Step 4 — Admin password (you can skip this)

Some parts of `mo clean` need `sudo` — your admin password — to clean system-level caches. When Mole detects it's running with no terminal attached (i.e. automated), it skips that step and continues cleanly. You'll see this in the log:

```
Running in non-interactive mode
• System-level cleanup skipped, requires sudo
• User-level cleanup will proceed automatically
```

**This is fine.** You still get full user-level cleanup (caches, logs, browser data, developer tool caches — which is most of what `mo clean` does). The system-level step is just a small extra.

> **Option A (recommended):** Do nothing. This is the safe default and works great.

<details>
<summary><strong>Option B — unlock system-level cleanup (advanced, optional)</strong></summary>

You can give your account passwordless admin rights so the system-level step also runs:

```bash
echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/busy-mole
sudo chmod 440 /etc/sudoers.d/busy-mole
```

**Important:** This is not scoped to Mole — your account can run *any* admin command without a password from then on. Only do this on a personal Mac that only you use. Not recommended for shared or work machines.

Verify it worked:
```bash
sudo -k && sudo whoami
```
Should print `root` with **no** password prompt.

Undo any time:
```bash
sudo rm /etc/sudoers.d/busy-mole
```
</details>

### Step 5 — Test it right now

```bash
bash ~/.local/bin/busy-mole.sh
```

Then check the log:
```bash
cat "$(/bin/ls -t ~/.local/state/busy-mole/*.log | head -n 1)"
```

**What a successful run looks like:**

```
=== busy-mole run started: Mon Sep 11 00:00:01 EDT 2026 ===
Using mo at: /opt/homebrew/bin/mo
--- mo clean ---
...cleaning output from Mole here...
(mo clean exit status: 0)
--- mo optimize ---
...optimize output from Mole here...
(mo optimize exit status: 0)
=== busy-mole run finished: Mon Sep 11 00:01:23 EDT 2026 ===
```

Look for both exit statuses to be `0`. If you see that, everything is working. **Don't move on until this looks right** — everything after this point just schedules the thing you've already confirmed works.

### Step 6 — Make the Mac wake up for it

Your Mac needs to be awake (not fully shut down) to run the scheduled job. If it's asleep at midnight, this wakes it up 5 minutes before:

```bash
sudo pmset repeat wakeorpoweron M 23:55:00
```

This wakes the Mac at 11:55 PM every Monday. The day letter is `M` for Monday.

Other days: `S` = Sunday, `T` = Tuesday, `W` = Wednesday, `R` = Thursday, `F` = Friday, `A` = Saturday.

> **Note:** If your Mac is fully shut down (not just asleep), no software can wake it. The machine needs to be asleep, not off. A locked screen is fine — you just need to be logged in.

---

## Checking on it later

```bash
# Is the job still registered with launchd (macOS's task scheduler)?
launchctl list | grep busy-mole

# List all log files, newest first
/bin/ls -lt ~/.local/state/busy-mole/

# Read the most recent log
cat "$(/bin/ls -t ~/.local/state/busy-mole/*.log | head -n 1)"
```

> **Note:** If `ls` gives you a strange error, you may have a custom `ls` replacement installed. Use `/bin/ls` instead (as shown above) to call the original macOS version.

Worth glancing at occasionally — an automation that fails silently for months is worse than no automation.

---

## Changing the schedule

Open the schedule file in any text editor (TextEdit, VS Code, etc.):

```
~/Library/LaunchAgents/com.busy-mole.weekly.plist
```

Find the `StartCalendarInterval` section and change the numbers. Here's what it looks like:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>1</integer>       <!-- 0/7 = Sunday, 1 = Monday, ... 6 = Saturday -->
    <key>Hour</key>
    <integer>0</integer>       <!-- 24-hour format: 0 = midnight, 14 = 2 PM, 23 = 11 PM -->
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

After saving, reload the schedule:

```bash
launchctl unload ~/Library/LaunchAgents/com.busy-mole.weekly.plist
launchctl load ~/Library/LaunchAgents/com.busy-mole.weekly.plist
```

---

## Uninstalling

```bash
bash uninstall.sh
```

This one command removes everything busy-mole created: the scheduled job, the runner script, all logs, the wake schedule (if you set it up), and the passwordless-sudo rule (if you set it up). It asks for your password once, for the two steps that need `sudo`.

**Mole itself (`mo`) is never touched** — it stays installed and works normally by hand afterward, exactly as before.

---

## Troubleshooting

**I'm completely stuck — where do I start?**

1. Open Terminal (search for it with Spotlight)
2. Type `which mo` and press Enter. If it says `mo not found`, install Mole first (see Requirements above)
3. Type `bash ~/.local/bin/busy-mole.sh` and press Enter. If it runs, the problem is with the schedule, not the script
4. Type `launchctl list | grep busy-mole`. If nothing shows up, the schedule didn't load — check for a plist syntax error with `plutil -lint ~/Library/LaunchAgents/com.busy-mole.weekly.plist`

---

**The log says `command not found: mo`.**

`mo` isn't at one of the paths the script checks. Run `which mo` in a normal terminal to find where it is, then add that folder to the `PATH=` line near the top of `~/.local/bin/busy-mole.sh`.

**The log shows "System-level cleanup skipped, requires sudo."**

This is expected if you chose Option A in Step 4. Mole detects it's running unattended and skips that one step cleanly on its own; everything else still completes.

**Nothing happened at all on the scheduled day.**

Check whether the Mac was actually awake at that time. If asleep and you skipped Step 6, that's very likely why — a missed launchd calendar job isn't guaranteed to run late.

**The log directory is `~/.local/state/busy-mole`, not `~/Library/Logs`.**

This is deliberate. `mo clean` scans and empties folders under `~/Library/Logs` as part of its normal job, which means a log file kept there could get swept away by the very tool it's recording.

---

## Glossary

| Term | What it means |
|---|---|
| **launchd** | macOS's built-in task scheduler — the system that runs apps and scripts on a schedule. busy-mole uses it to run Mole every week. |
| **launchctl** | The command-line tool for managing launchd jobs (loading, unloading, checking status). |
| **plist** | A settings file used by macOS (XML format). The `.plist` file tells launchd what to run and when. |
| **sudo** | A command that runs with admin privileges. macOS asks for your password when you use it. |
| **PATH** | A list of folders your Mac searches when you type a command. If `mo` isn't in one of these folders, the script can't find it. |
| **Homebrew (brew)** | A free package manager for macOS — a tool that installs other tools. Used to install Mole. |
| **`~` (tilde)** | Short for your home folder (e.g. `/Users/yourname`). `~/.local/bin` means `/Users/yourname/.local/bin`. |
| **pipe (`\|`)** | Sends the output of one command as the input to the next. Used to chain commands together. |

---

## For developers

```
busy-mole/
├── README.md
├── LICENSE
├── install.sh
├── uninstall.sh
├── scripts/
│   └── busy-mole.sh
└── launchd/
    └── com.busy-mole.weekly.plist
```

---

## Credit and license

- [Mole](https://github.com/tw93/mole), by [tw93](https://github.com/tw93), does all the actual cleaning. Licensed under **GPL-3.0** (with an added trademark clause) — check their repo for current terms.
- The files in this repo are original and released under the [MIT License](LICENSE).
