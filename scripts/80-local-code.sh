#!/bin/bash
# Symlink bin/local-code into ~/bin, same pattern as the opencode config step.
#
# ~/bin already exists (scripts/30-dirs.sh) and is expected to be on PATH.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/bin/local-code"
DEST="$HOME/bin/local-code"

if [ ! -f "$SRC" ]; then
    log_error "missing $SRC"
    exit 1
fi

if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
    log_skip "local-code already linked to this repo"
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

run mkdir -p "$HOME/bin"

if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    backup="$DEST.backup-$(date +%Y%m%d%H%M%S)"
    log_warn "existing $DEST found, moving it to $backup"
    mv "$DEST" "$backup"
fi

log_info "linking $DEST -> $SRC"
ln -s "$SRC" "$DEST"

path_line='export PATH="$HOME/bin:$PATH"'
if grep -qxF "$path_line" "$HOME/.zprofile" 2>/dev/null; then
    log_skip "$HOME/.zprofile already puts ~/bin on PATH"
else
    log_info "adding ~/bin to PATH in ~/.zprofile"
    run bash -c "printf '%s\n' '$path_line' >> '$HOME/.zprofile'"
fi
