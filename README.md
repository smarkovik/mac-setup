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
| `scripts/65-opencode.sh` | Link OpenCode's config into this repo |
| `scripts/70-macos-defaults.sh` | macOS UI preferences |
| `scripts/80-local-code.sh` | Link `local-code` into `~/bin` |
| `config/opencode/opencode.json` | The OpenCode config itself — edit this |
| `bin/local-code` | Control panel: pull/run/wipe the local coding models |
| `scripts/90-passwordless-sudo.sh` | Opt-in, see below |
| `tools/validate-brewfile.sh` | Check every `Brewfile` token exists |
| `tools/audit-defaults.sh` | Find which key macOS really uses for a setting |

### Adding or removing packages

Edit the `Brewfile` and re-run. Removing a line does **not** uninstall anything;
do that yourself with `brew uninstall` / `brew uninstall --cask`.

> **Do not reach for `brew bundle cleanup`.** It lists everything installed that
> is not in the `Brewfile` — which is not drift, it is the rest of your machine.
> On a real install it proposed removing `gh`, `awscli`, `ansible`, `pipx` and
> `ngrok`. The `Brewfile` is the subset this repo manages, never an inventory of
> everything you have.

Before committing a new entry, check the token exists:

```sh
./tools/validate-brewfile.sh
```

`brew bundle` fails the **entire** file on one bad token, so a single typo
takes every other package with it. CI runs this on a macOS runner for the same
reason.

### OpenCode configuration

`~/.config/opencode/opencode.json` is symlinked to `config/opencode/opencode.json`
in this repo, so the config is version-controlled and edits take effect
immediately — no copy step, nothing to re-sync.

```sh
./mac-setup.sh --only opencode
```

If you already have a config there, it is **moved aside** to
`opencode.json.backup-<timestamp>`, never overwritten. To keep those settings,
copy the backup over the repo's copy and re-run:

```sh
cp ~/.config/opencode/opencode.json.backup-* config/opencode/opencode.json
./mac-setup.sh --only opencode
```

**It points at local model servers, not a cloud provider.** Both entries use
`@ai-sdk/openai-compatible` against an OpenAI-shaped endpoint on localhost, so
neither needs an API key:

| Provider | `baseURL` | Served by |
|---|---|---|
| `ollama` | `http://localhost:11434/v1` | `ollama serve` |
| `llamacpp` | `http://127.0.0.1:8080/v1` | `llama-server` |

The model IDs in each `models` block are placeholders — replace them with what
your servers actually expose (`ollama list`, or whatever you passed to
`llama-server -m`). OpenCode sends the ID through verbatim; a name that does not
exist on the server fails at request time, not at load time.

There are no credentials here to protect. If you ever do add a cloud provider,
put the key in `~/.local/share/opencode/auth.json` via `opencode auth login` —
a directory this repo never reads, writes or links — or reference it rather than
embedding it, since OpenCode resolves `{env:VAR}` and `{file:path}` at load time:

```json
"apiKey": "{env:ANTHROPIC_API_KEY}"
```

JSON has no comments, so the notes live here rather than in the file. Full key
reference — `model`, `agent`, `mcp`, `permission`, `formatter`, `lsp` — is at
[opencode.ai/docs/config](https://opencode.ai/docs/config/).

#### `local-code` — the local model control panel

Three quants of the same model (`unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`
on the Hugging Face Hub), pulled through `ollama` and renamed to a short tag
so `ollama list` and OpenCode's model picker both show a size, not a
checkpoint filename:

| Tier | Quant | ~Size | Ollama tag |
|---|---|---|---|
| `small` | IQ4_XS | 16 GB | `qwen3-coder:small` |
| `mid` | Q5_K_M | 22 GB | `qwen3-coder:mid` |
| `big` | Q6_K | 25 GB | `qwen3-coder:big` |

`local-code` (symlinked to `~/bin` by `scripts/75-local-code.sh`, same
never-overwrite pattern as the OpenCode step) drives all three:

```sh
local-code list            # what's pulled, and disk free
local-code pull mid        # or: small | big | all
local-code run big         # pull if needed, start ollama, launch OpenCode
local-code wipe small      # or: mid | big | all - frees the disk back up
```

`pull` and `wipe` are the point: at 25 GB for the largest tier, keeping all
three on disk permanently is a real cost, so the workflow is to pull the
tier you need, run it, and wipe it when you are done with it rather than
let three quants sit there.

Q8_0 is deliberately not offered as a tier: on 48 GB of unified memory it
leaves almost no headroom for KV cache or anything else running, for a
quality jump that is the flattest part of the curve on a sparse MoE model
like this one. Pull it manually if you ever need to check that claim
yourself: `ollama pull hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q8_0`.

`ollama cp` copies only the manifest, not the weights, so renaming the long
Hub reference to a short tag after pulling is free; `ollama rm` only deletes
blobs no other manifest still references, so removing the long name right
after is safe.

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
