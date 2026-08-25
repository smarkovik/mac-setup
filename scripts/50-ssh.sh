#!/bin/bash
# SSH key for GitHub.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ed25519 is the current default: shorter, faster, and what GitHub recommends.
# An existing id_rsa is left alone rather than migrated.
KEY="$HOME/.ssh/id_ed25519"
LEGACY_KEY="$HOME/.ssh/id_rsa"

if [ -f "$KEY" ]; then
    log_skip "SSH key already exists at $KEY"
elif [ -f "$LEGACY_KEY" ]; then
    log_skip "existing RSA key found at $LEGACY_KEY, leaving it alone"
    KEY="$LEGACY_KEY"
else
    log_info "generating SSH key at $KEY"
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
    run ssh-keygen -t ed25519 -f "$KEY" -q -N "" -C "$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname)"
fi

if [ -f "$KEY.pub" ]; then
    log_warn "public key - add it at https://github.com/settings/keys"
    cat "$KEY.pub"
    if have pbcopy; then
        pbcopy < "$KEY.pub"
        log_info "(copied to clipboard)"
    fi
fi
