## mac-setup

**My personal machine setup — feel free to use, copy, clone, and contribute.**

Targets Apple Silicon on current macOS. No prerequisites: Homebrew installs the
Xcode Command Line Tools itself if they are missing.

### Run it

```sh
git clone git@github.com:smarkovik/mac-setup.git
cd mac-setup
./mac-setup.sh
```

Or straight from the terminal:

```sh
cd /tmp && curl -fsSL -o mac-setup.zip https://github.com/smarkovik/mac-setup/archive/refs/heads/main.zip && unzip -oq mac-setup.zip && cd mac-setup-main && ./mac-setup.sh
```

### It is safe to re-run

Every step is idempotent and reports when it has nothing to do, so this is
meant to be run repeatedly — not just once on a fresh laptop.

```sh
./mac-setup.sh --dry-run              # show what would change, change nothing
./mac-setup.sh --list                 # list the steps
./mac-setup.sh --only macos-defaults  # run one step
./mac-setup.sh --force                # re-apply steps that would be skipped
```

The macOS defaults step compares every setting against its live value and writes
only what differs, so it **converges**: change something in System Settings and
the next run puts it back. Dock, Finder and SystemUIServer are restarted only
when something actually changed, so a run with no drift closes none of your
Finder windows. `--force` rewrites every setting regardless of its current
value.

### Layout

| Path | What it is |
|---|---|
| `mac-setup.sh` | Orchestrator: flags, step ordering |
| `Brewfile` | The package list — source of truth for what gets installed |
| `scripts/lib.sh` | Shared logging, dry-run and `defaults` comparison helpers |
| `scripts/10-homebrew.sh` | Install Homebrew, put it on `PATH` |
| `scripts/20-packages.sh` | Apply the `Brewfile` |
| `scripts/25-python.sh` | Put Homebrew's CPython ahead of Apple's on `PATH` |
| `scripts/30-dirs.sh` | Home folder structure |
| `scripts/40-git.sh` | Global git config |
| `scripts/50-ssh.sh` | SSH key for GitHub |
| `scripts/60-zsh.sh` | oh-my-zsh |
| `scripts/70-macos-defaults.sh` | macOS UI preferences |
| `scripts/90-passwordless-sudo.sh` | Opt-in, see below |
| `tools/validate-brewfile.sh` | Check every `Brewfile` token exists |
| `tools/audit-defaults.sh` | Find which key macOS really uses for a setting |

### Adding or removing packages

Edit the `Brewfile` and re-run. To see what is installed but no longer listed:

```sh
brew bundle cleanup --file=Brewfile            # report
brew bundle cleanup --file=Brewfile --force    # actually uninstall
```

Before committing a new entry, check the token exists:

```sh
./tools/validate-brewfile.sh
```

`brew bundle` fails the **entire** file on one bad token, so a single typo
takes every other package with it. CI runs this on a macOS runner for the same
reason.

### Checking a macOS setting is still real

`defaults write` succeeds against a key nothing reads, so a setting can be dead
for years without any error — `com.apple.menuextra.battery ShowPercent` sat in
here long after the battery item moved to Control Center in Big Sur. Reading the
value back cannot detect that; only watching what the system itself writes can.

```sh
./tools/audit-defaults.sh                    # watch the domains we touch
./tools/audit-defaults.sh com.apple.dock     # or specific ones
```

It snapshots the domains, waits while you change one thing in System Settings,
then diffs and names the key macOS actually writes today. Worth a pass after
each major macOS release — there is no reliable published source for this, and
the usual reference (macos-defaults.com) has no macOS 26 data at all.

### Python

`brew "python"` tracks whatever Homebrew currently calls current, so this
follows new releases rather than pinning a version.

`python3` resolves to Homebrew's automatically, because the `brew shellenv` line
puts `/opt/homebrew/bin` ahead of `/usr/bin`. Homebrew deliberately does not
link an unversioned `python`/`pip`, so `scripts/25-python.sh` adds the formula's
`libexec/bin` to `PATH` — that is what makes plain `python` and `pip` work.
Apple's remains at `/usr/bin/python3` if you need it explicitly.

### If you are not me

Fork it. Three things are mine and you will want to change them:

- **git identity** in `scripts/40-git.sh`. It only fills in what is not already
  set, so it will not overwrite yours — but on a fresh machine you would get
  mine. Override with `GIT_USER_NAME` / `GIT_USER_EMAIL`, or just edit the file.
- **macOS defaults** in `scripts/70-macos-defaults.sh` are my preferences,
  including `en_GB`/EUR/Centimeters locale settings.
- **The `Brewfile`** is the set of apps I actually run. It is a plain list —
  delete the lines you do not want.

### Passwordless sudo

Not part of the default run. Nothing in this repo needs it — Homebrew prompts
for its own sudo, and every `defaults write` here is user-level.

```sh
./mac-setup.sh --only passwordless-sudo    # enable
sudo rm /private/etc/sudoers.d/$(whoami)   # undo
```

It is permanent until you remove that file.
