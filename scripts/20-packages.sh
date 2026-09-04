#!/bin/bash
# Apply the Brewfile. Idempotent by construction: brew bundle installs what is
# missing and leaves everything else alone.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Brewfile"

if ! have brew; then
    # On a fresh machine a --dry-run has not actually installed brew, so this
    # is expected rather than an error: report and move on.
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] brew not present yet; would apply %s\n' "$BREWFILE"
        exit 0
    fi
    log_error "brew not on PATH - run the homebrew step first"
    exit 1
fi

if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    log_skip "all Brewfile entries already installed"
else
    log_info "installing missing Brewfile entries"
    run brew bundle --file="$BREWFILE"
fi

# NOTE: deliberately no `brew bundle cleanup` drift report here.
#
# `cleanup` lists everything installed that is not in the Brewfile - which is
# not "drift", it is simply the rest of your machine. On a real install it
# proposed uninstalling gh, awscli, ansible, pipx, ngrok and their dependencies,
# under a message telling you to run `--force`. The Brewfile is the subset this
# repo manages, never an inventory of the whole system, so that comparison can
# only ever produce dangerous advice.
