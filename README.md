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

The macOS defaults step restarts Dock, Finder and SystemUIServer, which closes
your Finder windows — so it fingerprints itself and skips entirely when nothing
in it has changed since the last run. `--force` overrides that.

### Layout

| Path | What it is |
|---|---|
| `mac-setup.sh` | Orchestrator: flags, step ordering |
| `Brewfile` | The package list — source of truth for what gets installed |
| `scripts/lib.sh` | Shared logging, dry-run and change-stamp helpers |
| `scripts/10-homebrew.sh` | Install Homebrew, put it on `PATH` |
| `scripts/20-packages.sh` | Apply the `Brewfile` |
| `scripts/30-dirs.sh` | Home folder structure |
| `scripts/40-git.sh` | Global git config |
| `scripts/50-ssh.sh` | SSH key for GitHub |
| `scripts/60-zsh.sh` | oh-my-zsh |
| `scripts/70-macos-defaults.sh` | macOS UI preferences |
| `scripts/90-passwordless-sudo.sh` | Opt-in, see below |

### Adding or removing packages

Edit the `Brewfile` and re-run. To see what is installed but no longer listed:

```sh
brew bundle cleanup --file=Brewfile            # report
brew bundle cleanup --file=Brewfile --force    # actually uninstall
```

### If you are not me

Fork it. Two things are mine and you will want to change them:

- **git identity** in `scripts/40-git.sh`. It only fills in what is not already
  set, so it will not overwrite yours — but on a fresh machine you would get
  mine. Override with `GIT_USER_NAME` / `GIT_USER_EMAIL`, or just edit the file.
- **macOS defaults** in `scripts/70-macos-defaults.sh` are my preferences,
  including `en_GB`/EUR/Centimeters locale settings.

### Passwordless sudo

Not part of the default run. Nothing in this repo needs it — Homebrew prompts
for its own sudo, and every `defaults write` here is user-level.

```sh
./mac-setup.sh --only passwordless-sudo    # enable
sudo rm /private/etc/sudoers.d/$(whoami)   # undo
```

It is permanent until you remove that file.
