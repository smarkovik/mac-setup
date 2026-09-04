# Declarative package list. Applied with `brew bundle --file=Brewfile`.
#
# This file is the source of truth for what gets installed. Adding a line and
# re-running installs it; `brew bundle cleanup` reports what is installed but no
# longer listed here.

# --- ai / coding -------------------------------------------------------------
# The Claude desktop app, which is where Claude Code's desktop experience lives.
# NOTE: the cask literally named "claude-code" is the *terminal* CLI (it installs
# a `claude` binary, no app), so it is deliberately not the one used here.
cask "claude"
cask "cursor"
# The Ollama desktop app. This also installs the `ollama` CLI binary, so it
# covers both the GUI and running a local server for opencode to talk to.
# For CLI/server only and no app, swap this for: brew "ollama"
cask "ollama-app"
# The OpenCode desktop app. NOTE: the token is "opencode-desktop"; a bare
# "opencode" cask does not exist, which is why this was previously (and
# wrongly) assumed to be terminal-only. The `opencode` CLI *formula* does
# exist but is deliberately not installed - the app is what gets used.
cask "opencode-desktop"
# Block's Goose. NOTE: the cask token is "block-goose", not "goose" - the
# latter does not exist.
cask "block-goose"

# --- editors -----------------------------------------------------------------
cask "visual-studio-code"
cask "zed"

# --- browsers ----------------------------------------------------------------
cask "google-chrome"
cask "microsoft-edge"
cask "brave-browser"

# --- apps --------------------------------------------------------------------
cask "1password"
cask "dropbox"
cask "ngrok"
cask "notion-calendar"
cask "whatsapp"
cask "viber"
cask "slack"
# NOTE: the token is "gitup-app", not "gitup" - the latter does not exist.
# This was carried over broken from the original Ansible playbook.
cask "gitup-app"

# --- cli ---------------------------------------------------------------------
brew "mc"
brew "git-lfs"
brew "ffmpeg"
brew "wget"
brew "tree"
# npm ships inside the node formula; there is no standalone `npm` formula.
brew "node"
# Latest CPython, not the one Apple ships. The `python` alias tracks whatever
# Homebrew currently considers current (3.14 as of writing), so this keeps
# following it rather than pinning. See scripts/25-python.sh for the PATH side.
brew "python"
