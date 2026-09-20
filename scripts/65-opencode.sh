#!/bin/bash
# OpenCode configuration.
#
# opencode.json is generated from opencode.json.tmpl by bin/opencode-config,
# with only the ollama models actually installed (OpenCode does not auto-detect
# them), then symlinked into ~/.config/opencode alongside the prompts dir and
# the global AGENTS.md OpenCode auto-loads every session. Edit the *template*,
# not the generated json. OpenCode resolves the config's relative
# `{file:./prompts/...}` refs against the symlink's own directory, so the
# prompts dir MUST be linked next to the json.
#
# This step only touches those paths: anything `opencode auth login` stores
# lives in ~/.local/share/opencode/auth.json, never read, written or linked here.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/config/opencode"
DEST_DIR="$HOME/.config/opencode"

if [ ! -f "$SRC_DIR/opencode.json.tmpl" ]; then
    log_error "missing $SRC_DIR/opencode.json.tmpl"
    exit 1
fi

if [ "${DRY_RUN:-0}" != "1" ]; then
    run mkdir -p "$DEST_DIR"
    # Generate opencode.json from the template with only the installed ollama
    # models, so the picker matches `ollama list`. Regenerated every run.
    run "$REPO_DIR/bin/opencode-config"
fi

# Link one repo path into ~/.config/opencode. Anything already linked to us is
# left alone; anything else there is moved aside, never overwritten - a config
# you have been using is worth more than the stub in this repo.
link_config() {
    local src="$1" dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        log_skip "$(basename "$dest") already linked to this repo"
        return 0
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            printf '     [dry-run] would back up %s and link it to %s\n' "$dest" "$src"
        else
            printf '     [dry-run] would link %s -> %s\n' "$dest" "$src"
        fi
        return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local backup
        backup="$dest.backup-$(date +%Y%m%d%H%M%S)"
        log_warn "existing $(basename "$dest") found, moving it to $backup"
        mv "$dest" "$backup"
    fi

    log_info "linking $dest -> $src"
    ln -s "$src" "$dest"
}

link_config "$SRC_DIR/opencode.json" "$DEST_DIR/opencode.json"
link_config "$SRC_DIR/prompts" "$DEST_DIR/prompts"
link_config "$SRC_DIR/AGENTS.md" "$DEST_DIR/AGENTS.md"
