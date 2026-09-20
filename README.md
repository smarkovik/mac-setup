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

### One step failing doesn't stop the rest

This is meant to be pushed to and re-run over time, not just for a fresh
laptop, so a step that fails is reported and skipped rather than stopping
everything after it - a broken Brewfile cask shouldn't block `git`, `ssh`,
`zsh`, or `opencode` from doing their job. Each step also prints which
number it is and how long it took:

```
==> [2/10] packages
     ...
 ===> step 'packages' failed after 41s (exit 1) - continuing with the remaining steps
 ===> once it is fixed, re-run just that step:
 ===>     ./mac-setup.sh --only packages

==> [3/10] python
     ...
 ===> finished in 96s with 1 step(s) needing attention:
 ===>   - packages (re-run: ./mac-setup.sh --only packages)
```

`brew bundle` itself already keeps installing the rest of the Brewfile past
one bad cask - this is the same idea one level up, across steps. A cask that
fails because of something already in `/Applications` (a version mismatch,
usually) needs a manual look, not automatic deleting - `rm -rf` the app
yourself, then `--only packages` again.

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
| `config/opencode/prompts/` | System prompts for the planner/architect/debugger/reviewer agents |
| `config/opencode/AGENTS.md` | Always-on global guidance OpenCode loads every session |
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

`local-code` (symlinked to `~/bin` by `scripts/80-local-code.sh`, same
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

#### Agents: planner, architect, debugger, reviewer

Four agents in `config/opencode/opencode.json`, each scoped to one job with
its own model and permissions, prompts in `config/opencode/prompts/`:

| Agent | Mode | Model | Edit | Bash |
|---|---|---|---|---|
| `planner` | primary | `qwen3-coder:big` | deny | ask |
| `architect` | primary | `qwen3-coder:big` | deny | ask |
| `debugger` | subagent | `qwen3-coder:mid` | ask | allow |
| `reviewer` | subagent | `qwen3-coder:big` | deny | deny |

`planner`, `architect` and `reviewer` cannot edit files - they read and
reason, so a bad call costs nothing, and `big` (Q6) trades speed for reasoning
quality since there's no tight loop to keep fast. `debugger` can run commands
and edit, because reproducing a failure and fixing it needs both; it runs on
`mid` (Q5) because that loop is interactive and speed matters more there than
the last bit of quality.

`planner` breaks a spec into small, vertically-sliced tasks before any code;
`architect` reviews or designs structure; `debugger` reproduces and fixes;
`reviewer` reads a diff for real, most-severe-first findings.

Invoke a subagent with `@debugger` or `@reviewer` in OpenCode, or switch to
`planner` or `architect` as your primary agent.

#### AGENTS.md: always-on house style

`config/opencode/AGENTS.md` is symlinked into `~/.config/opencode` and loaded
by OpenCode on every session, so its guidance applies to every agent. It holds
the default working style - lazy in the good way: YAGNI, reuse before writing,
stdlib and native platform features before dependencies, the shortest change
that actually works, root-cause over symptom. Edit it to change how every
agent behaves by default.

> This repo's AI setup lives entirely in OpenCode - agents, prompts and
> `AGENTS.md`, all under `config/opencode/` - not in Claude Code. `.claude/`
> is gitignored.

#### LSP

```json
"lsp": true
```

Turns on every language server OpenCode ships built-in support for, each
activating only when its own project already satisfies it (a `typescript`
dependency, `pyright` installed, and so on) - this repo doesn't install any
of them for you. Gives every agent real go-to-definition and references
instead of grepping for text, which matters most for architecture and
review: "what else calls this" is a structural question, not a text search.

#### MCP: GitHub

```json
"mcp": {
  "github": {
    "type": "local",
    "command": ["docker", "run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "-e", "GITHUB_TOOLSETS=repos,issues,pull_requests,actions,code_security", "ghcr.io/github/github-mcp-server"],
    "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_PERSONAL_ACCESS_TOKEN}" },
    "enabled": false
  }
}
```

Lets the `reviewer` agent look at a real PR - diffs, check runs, existing
review threads - instead of only a local diff. **Disabled by default**:
it needs Docker (not installed by this repo - a real dependency, add
`cask "docker"` yourself if you want it) and a GitHub PAT in
`GITHUB_PERSONAL_ACCESS_TOKEN`. Flip `enabled` to `true` once both exist.

Sentry MCP (`@sentry/mcp-server`) is a reasonable second addition if you use
Sentry, for the same reason - direct issue/error lookup instead of pasting
stack traces in by hand - but it authenticates via an OAuth flow per
account, so it isn't pre-wired here; add it the same way once you've looked
at [github.com/getsentry/sentry-mcp](https://github.com/getsentry/sentry-mcp).

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
