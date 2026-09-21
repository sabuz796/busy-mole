# busy-mole 🐭

[![lint](https://github.com/sabuz796/busy-mole/actions/workflows/lint.yml/badge.svg)](https://github.com/sabuz796/busy-mole/actions/workflows/lint.yml) [![integration](https://github.com/sabuz796/busy-mole/actions/workflows/test.yml/badge.svg)](https://github.com/sabuz796/busy-mole/actions/workflows/test.yml)

**Your Mac cleans itself every Monday at midnight. You never have to think about it.**

busy-mole is a tiny helper that makes [Mole](https://github.com/tw93/mole) — a free, open-source Mac cleaning tool — run automatically every week. No clicking, no remembering, no paid apps.

- 🧹 **Mole** does the actual cleaning (deletes junk files your Mac doesn't need)
- ⏰ **busy-mole** is just the weekly alarm clock for it
- 🔔 You get a quiet notification when a cleanup finishes — and a loud one if something ever goes wrong
- 🔒 Nothing ever leaves your Mac — no accounts, no tracking, no cloud

*busy-mole is unofficial and not affiliated with the Mole project. All the cleaning is done by Mole itself, full credit to [tw93](https://github.com/tw93).*

---

## What exactly happens?

Once a week (Monday, 12:00 AM), your Mac quietly runs two commands:

1. **`mo clean`** — deletes junk: app caches, old logs, browser caches, developer-tool leftovers
2. **`mo optimize`** — refreshes system caches and services

Then it saves a short log file and shows you a notification with how much disk space is free. That's the whole thing. It works when the screen is locked, and if the Mac is asleep at midnight it simply runs when the Mac next wakes up.

## Is it safe? What gets deleted?

**Deleted (junk your Mac rebuilds on its own):**
- App and system caches
- Old log files
- Browser caches
- Developer tool caches (Xcode, Homebrew, npm, etc.)

**Never touched:**
- Your documents, photos, music, or videos
- Browser bookmarks, history, or saved passwords
- App settings and preferences
- Anything you created

Only rebuildable junk is deleted — and you don't have to take our word for it. After installing Mole (next section), run this to see exactly what *would* be deleted, without deleting anything:

```bash
mo clean --dry-run
```

> **One small exception:** a few *system-level* caches need your admin password, and a scheduled job can't type passwords — so those are simply skipped. Nothing hangs, nothing breaks; you still get almost all of the benefit. Advanced users can unlock them via [Optional extras](#optional-extras).

---

## Privacy

**Nothing to hide: busy-mole only schedules Mole — it does nothing else.**

- **busy-mole itself** is three small shell scripts you can read in a few minutes. They copy one file, register a weekly schedule, and run `mo clean` + `mo optimize`. That's the entire feature list — no network, no accounts, no tracking; there's simply nothing in it that *could* collect your data.
- **All the actual work — and all the safety decisions — are Mole's.** Mole has no telemetry and reports nothing, which is written into its public [security design](https://github.com/tw93/mole/blob/main/docs/SECURITY_DESIGN.md). Its only network use is checking for its own updates, and *only* when you open its interactive menu or run `mo update` yourself — never during the scheduled cleanups busy-mole runs.
- Notifications are shown by macOS itself, locally. Logs live only in `~/.local/state/busy-mole/` and clean themselves up (newest 20 kept).

The only network involved in this whole setup is the day you download Mole and busy-mole. After that: none.

> **Note:** Homebrew (if you used it to install Mole) has its own separate analytics setting — see `brew analytics`. That's Homebrew itself, unrelated to busy-mole or Mole.

---

## Before you start

You need two things:

1. **A Mac with macOS 12 or newer** (any Mac from roughly 2016 onward)
2. **Mole installed** — remember, busy-mole is only the alarm clock; Mole is the cleaner

### Install Mole

Open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter). Then paste this and press Enter:

```bash
brew install mole
```

<details>
<summary><strong>Don't have "brew"? Click here</strong></summary>

brew is [Homebrew](https://brew.sh), a free tool that installs other tools — either follow the one-line setup on [brew.sh](https://brew.sh) and then run the command above, or skip brew entirely and use Mole's own installer:

```bash
curl -fsSL https://raw.githubusercontent.com/tw93/mole/main/install.sh | bash
```
</details>

Check that it worked:

```bash
mo --version
```

If you see a version number, you're ready.

---

## Install busy-mole (3 steps)

### Step 1 — Get busy-mole

In Terminal, paste:

```bash
git clone https://github.com/sabuz796/busy-mole.git
cd busy-mole
```

<details>
<summary><strong>No git? Download it by hand instead</strong></summary>

1. Open https://github.com/sabuz796/busy-mole in your browser
2. Click the green **Code** button → **Download ZIP**
3. Double-click the downloaded `.zip` file to unzip it
4. In Terminal, type `cd ` (with a space at the end), then drag the unzipped folder into the Terminal window and press Enter
</details>

### Step 2 — Install

```bash
bash install.sh
```

That's it. The installer checks that Mole is present, copies one small script into your home folder, and registers the weekly schedule with macOS.

### Step 3 — Try it once, right now

```bash
bash ~/.local/bin/busy-mole.sh
```

You'll watch Mole clean your Mac live in your terminal (a real run, not a drill — worth seeing once with your own eyes). Then, after each weekly run, a notification arrives saying something like *"Weekly cleanup finished. Disk free: 362Gi -> 385Gi"* (that's gigabytes of free space before → after).

**If that worked, you're done.** Everything from here on happens automatically.

---

## How do I know it's still working, months from now?

You get a notification after each **weekly** run (manual runs show live output in the terminal instead, so no notification), and normally that's all you need. If you ever want proof:

```bash
# Read the newest log
cat "$(/bin/ls -t ~/.local/state/busy-mole/2*.log | head -n 1)"
```

A healthy log shows `(mo clean exit status: 0)` and `(mo optimize exit status: 0)`, plus `Disk free at start` / `Disk free at end` lines. And if a run ever *fails*, the notification makes a sound — a broken automation can't hide.

---

## Uninstall completely (one command)

In Terminal:

```bash
cd busy-mole
bash uninstall.sh
```

This removes **everything** busy-mole put on your Mac: the weekly schedule, the helper script, and all its logs. If you set up any optional extras (below), it handles those too — it shows you the wake schedule and asks before cancelling it, and removes the passwordless-admin rule if you created one. Your password is only asked for if those extras were actually set up.

> **Deleted the busy-mole folder already?** Download it again (Step 1) — the uninstaller lives inside it.

**Mole itself stays installed** — busy-mole never touches it, and `mo` keeps working normally by hand. If you want Mole gone too:

```bash
brew uninstall mole
```

After that, your Mac is exactly as it was before you found this page.

---

## Optional extras

Everything below is skippable — busy-mole works great without any of it.

<details>
<summary><strong>🔁 Change the day or time</strong></summary>

Open this file in any text editor:

```
~/Library/LaunchAgents/com.busy-mole.weekly.plist
```

Find the `StartCalendarInterval` section and change the numbers:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>1</integer>       <!-- 0/7 = Sunday, 1 = Monday, ... 6 = Saturday -->
    <key>Hour</key>
    <integer>0</integer>       <!-- 24-hour: 0 = midnight, 14 = 2 PM, 23 = 11 PM -->
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

Then reload the schedule:

```bash
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.busy-mole.weekly.plist
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.busy-mole.weekly.plist
```

If you also set up the wake-the-Mac extra below, update that too — it uses different day letters (`S` = Saturday, `U` = Sunday there).
</details>

<details>
<summary><strong>😴 Wake the Mac so it runs at midnight sharp</strong></summary>

You don't need this: if the Mac is asleep at midnight, the cleanup simply runs later, when the Mac next wakes. The only case a run is skipped entirely is if the Mac is fully **shut down** at midnight.

If you want it to run at midnight sharp anyway, this wakes the Mac 5 minutes early:

```bash
sudo pmset repeat wakeorpoweron M 23:55:00
```

The day letter is `M` for Monday; the full set is `MTWRFSU`:

| Letter | Day |
|---|---|
| `M` | Monday |
| `T` | Tuesday |
| `W` | Wednesday |
| `R` | Thursday |
| `F` | Friday |
| `S` | **Saturday** |
| `U` | Sunday |

⚠️ Watch out: `S` is **Saturday** and `U` is Sunday (think "U" for s**U**nday) — different from the schedule file, where `Weekday` 0 or 7 means Sunday. Change the day in **both** places or they'll disagree.

> **Note:** A Mac that is fully shut down can't be woken for this. Asleep is fine, locked is fine — you just need to be logged in.
</details>

<details>
<summary><strong>🔓 Also clean system-level caches (advanced)</strong></summary>

By default, a few system-level caches are skipped because they need your admin password. In the log you'll see:

```
Running in non-interactive mode
• System-level cleanup skipped, requires sudo
• User-level cleanup will proceed automatically
```

This is normal and fine. If you want those caches cleaned too, you can give your account passwordless admin rights:

```bash
echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/busy-mole
sudo chmod 440 /etc/sudoers.d/busy-mole

# Validate the file — a broken sudoers file can break sudo entirely.
# Must print "parsed OK". If it doesn't, remove the file immediately:
#   sudo rm /etc/sudoers.d/busy-mole
sudo visudo -cf /etc/sudoers.d/busy-mole
```

**Important:** this is not limited to Mole — from then on, *anything* running as you can run admin commands without a password. Only do this on a personal Mac that only you use.

Verify (should print `root` with **no** password prompt):

```bash
sudo -k && sudo whoami
```

Undo any time (`uninstall.sh` also removes this automatically):

```bash
sudo rm /etc/sudoers.d/busy-mole
```
</details>

<details>
<summary><strong>🛡️ Protect a specific cache from cleaning</strong></summary>

If there's a cache you want Mole to leave alone in these automated runs, protect it once:

```bash
mo clean --whitelist
```

Mole remembers your choice. To see what past runs actually cleaned:

```bash
mo history
```
</details>

<details>
<summary><strong>🖼️ A mouse icon on the notifications</strong></summary>

Notifications sent by scripts always show macOS's generic Script Editor icon — Apple doesn't let plain scripts choose one. If you'd like the busy-mole mouse 🐭 on your notifications, install the free [terminal-notifier](https://github.com/julienXX/terminal-notifier) tool:

```bash
brew install terminal-notifier
```

busy-mole detects it automatically from the next run — no settings to change. (Honest detail: the icon appears as a thumbnail on the notification; the small app icon still belongs to the tool that posts it.)

Without terminal-notifier, everything works exactly as before — this is pure decoration.
</details>

---

## Troubleshooting

**I'm completely stuck — where do I start?**

1. Open Terminal (press `Cmd + Space`, type `Terminal`, press Enter)
2. Type `which mo` and press Enter. If it says `mo not found`, install Mole first (see [Before you start](#before-you-start))
3. Type `bash ~/.local/bin/busy-mole.sh` and press Enter. If it runs, the problem is the schedule, not the script — re-run `bash install.sh` from the busy-mole folder

---

**The log says `command not found: mo`.**

`mo` isn't in one of the folders the script checks. Run `which mo` in a normal Terminal to see where it lives, then add that folder to the `PATH=` line near the top of `~/.local/bin/busy-mole.sh`.

---

**The log shows "System-level cleanup skipped, requires sudo".**

That's normal — see [Is it safe?](#is-it-safe-what-gets-deleted). The scheduled job skips the few caches that need your admin password; everything else still completes.

---

**Nothing happened at midnight on the scheduled day.**

- **Mac was asleep?** That's normal — the cleanup runs when the Mac wakes. Check the log after the next wake; the run will be there, just later than midnight.
- **Mac was fully shut down?** Then the run was skipped. It'll run next week — or set up the wake-the-Mac extra above.
- **Schedule missing?** Run `launchctl list | grep busy-mole`. If nothing shows up, re-run `bash install.sh`.

---

**No notifications appear after a weekly run.**

macOS files these notifications under **Script Editor** (that's the component that sends them). Enable them in System Settings → Notifications → Script Editor. They also always show the Script Editor icon — that's normal for script-based notifications. (Want the busy-mole mouse 🐭 instead? See [Optional extras](#optional-extras).)

---

**Why are the logs in `~/.local/state/busy-mole` and not `~/Library/Logs`?**

On purpose: `mo clean` clears folders under `~/Library/Logs` as part of its job, so a log kept there could be deleted by the very tool it's recording.

---

## Glossary (what these words mean)

| Term | What it means |
|---|---|
| **Mole / `mo`** | The free cleaning tool that does the actual work. Its command is called `mo`. |
| **launchd** | macOS's built-in task scheduler — runs things on a schedule. busy-mole uses it for the weekly run. |
| **plist** | A macOS settings file (XML). The `.plist` file tells launchd what to run and when. |
| **Terminal** | The app you type commands into (find it with `Cmd + Space`). |
| **sudo** | A command that needs your admin password. |
| **Homebrew (brew)** | A free tool that installs other tools. Used to install Mole. |
| **cache** | Temporary files apps create to run faster. Safe to delete — they're rebuilt automatically. |
| **`~` (tilde)** | Short for your home folder, e.g. `/Users/yourname`. |

---

## For developers

```
busy-mole/
├── README.md
├── LICENSE
├── install.sh        # copies the runner + icon, registers the launchd job (bootstrap)
├── uninstall.sh      # removes everything busy-mole created (never touches Mole)
├── scripts/
│   └── busy-mole.sh  # runs `mo clean` + `mo optimize`, logs, notifies, rotates logs
├── assets/
│   └── icon.png        # notification icon (Twemoji mouse, CC-BY 4.0)
├── launchd/
│   └── com.busy-mole.weekly.plist   # Monday 00:00, background priority
└── .github/
    └── workflows/
        ├── lint.yml  # shellcheck + syntax checks on every push
        └── test.yml  # full install → run → uninstall round-trip on a clean Mac
```

---

## Credit and license

- [Mole](https://github.com/tw93/mole), by [tw93](https://github.com/tw93), does all the actual cleaning. Licensed under **GPL-3.0** (with an added trademark clause) — check their repo for current terms.
- The notification icon is the mouse emoji from [Twemoji](https://github.com/twitter/twemoji), licensed [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- The files in this repo are original and released under the [MIT License](LICENSE).
