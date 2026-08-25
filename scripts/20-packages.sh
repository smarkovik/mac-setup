#!/bin/bash
# Apply the Brewfile. Idempotent by construction: brew bundle installs what is
# missing and leaves everything else alone.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Brewfile"

if ! have brew; then
    log_error "brew not on PATH - run the homebrew step first"
    exit 1
fi

if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    log_skip "all Brewfile entries already installed"
else
    log_info "installing missing Brewfile entries"
    run brew bundle --file="$BREWFILE"
fi

# Report drift without acting on it: removing a line from the Brewfile should
# be a deliberate uninstall, not a side effect of the next run.
if ! brew bundle cleanup --file="$BREWFILE" 2>/dev/null | grep -q '^$'; then
    extra=$(brew bundle cleanup --file="$BREWFILE" 2>/dev/null || true)
    if [ -n "$extra" ]; then
        log_warn "installed but not in the Brewfile (run 'brew bundle cleanup --force' to remove):"
        printf '%s\n' "$extra"
    fi
fi
