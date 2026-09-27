#!/bin/bash
# OpenCode platform layer (skills, markdown agents, GitHub MCP via gh).
#
# Runs AFTER scripts/65-opencode.sh. Assumes ~/.config/opencode already has
# opencode.json (+ prompts) linked from this repo. Does not touch auth.json or
# OpenCode Desktop UI state under ~/Library/Application Support/ai.opencode.desktop.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/config/opencode"
DEST_DIR="$HOME/.config/opencode"

if [ ! -d "$DEST_DIR" ] || { [ ! -e "$DEST_DIR/opencode.json" ] && [ ! -e "$DEST_DIR/opencode.jsonc" ]; }; then
    log_error "OpenCode base config missing under $DEST_DIR — run the opencode step first"
    exit 1
fi

for need in agents skills bin/github-mcp-via-gh.sh; do
    if [ ! -e "$SRC_DIR/$need" ]; then
        log_error "missing $SRC_DIR/$need"
        exit 1
    fi
done

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

link_config "$SRC_DIR/agents" "$DEST_DIR/agents"
link_config "$SRC_DIR/skills" "$DEST_DIR/skills"
link_config "$SRC_DIR/bin" "$DEST_DIR/bin"

# Expose the health check on PATH (~/bin, created by scripts/30-dirs.sh).
if [ "${DRY_RUN:-0}" != "1" ]; then
    run mkdir -p "$HOME/bin"
fi
link_config "$REPO_DIR/bin/opencode-doctor" "$HOME/bin/opencode-doctor"

# Regenerate opencode.json so MCP github (gh wrapper) from the tmpl is live.
if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '     [dry-run] would regenerate opencode.json via bin/opencode-config\n'
else
    run "$REPO_DIR/bin/opencode-config"
    log_info "regenerated opencode.json (github MCP via gh+npx)"
fi

# Light doctor
if [ "${DRY_RUN:-0}" = "1" ]; then
    log_info "dry run — skip doctor checks"
    exit 0
fi

ok=1
[ -x "$DEST_DIR/bin/github-mcp-via-gh.sh" ] || { log_warn "wrapper not executable"; ok=0; }
[ -f "$DEST_DIR/agents/builder.md" ] || { log_warn "builder agent missing"; ok=0; }
[ -f "$DEST_DIR/skills/feature-development/SKILL.md" ] || { log_warn "skills missing"; ok=0; }
if command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
    log_info "gh auth token: ok"
else
    log_warn "gh auth token not available — GitHub MCP will fail until: gh auth login"
fi
if [ "$ok" = "1" ]; then
    log_info "opencode-platform ready — restart OpenCode Desktop to load MCP/skills/agents"
else
    log_warn "opencode-platform installed with warnings"
fi
