#!/bin/bash
# OpenCode configuration.
#
# Symlinks ~/.config/opencode/opencode.json to the copy in this repo, so the
# config is version-controlled and edits take effect immediately.
#
# The config points OpenCode at the local model servers (ollama, llama-server),
# which need no credentials. This step only ever touches the config file:
# anything `opencode auth login` stores lives in
# ~/.local/share/opencode/auth.json, a different directory that is never read,
# written or linked here.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/config/opencode/opencode.json"
DEST_DIR="$HOME/.config/opencode"
DEST="$DEST_DIR/opencode.json"

if [ ! -f "$SRC" ]; then
    log_error "missing $SRC"
    exit 1
fi

# Already linked to us - nothing to do.
if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
    log_skip "opencode.json already linked to this repo"
    exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        printf '     [dry-run] would back up %s and link it to %s\n' "$DEST" "$SRC"
    else
        printf '     [dry-run] would link %s -> %s\n' "$DEST" "$SRC"
    fi
    exit 0
fi

run mkdir -p "$DEST_DIR"

# Anything already there is moved aside, never overwritten. A config you have
# been using is worth more than the stub in this repo - adopt it by copying the
# backup over $SRC and committing it.
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup="$DEST.backup-$(date +%Y%m%d%H%M%S)"
    log_warn "existing config found, moving it to $backup"
    log_warn "to keep those settings: cp '$backup' '$SRC' && re-run"
    mv "$DEST" "$backup"
fi

log_info "linking $DEST -> $SRC"
ln -s "$SRC" "$DEST"
