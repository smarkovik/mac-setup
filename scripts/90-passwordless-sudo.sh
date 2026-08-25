#!/bin/bash
# OPT-IN. Not part of the default run - invoke with:
#     ./mac-setup.sh --only passwordless-sudo
#
# Grants the current user passwordless sudo, permanently, until the file is
# removed by hand:
#     sudo rm /private/etc/sudoers.d/$(whoami)
#
# Nothing else in this repo needs it: Homebrew prompts for its own sudo when
# required, and every `defaults write` here is user-level.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

shell_user="$(whoami)"
sudoers_dir="/private/etc/sudoers.d"
sudoers_file="$sudoers_dir/$shell_user"
entry="$shell_user ALL=(ALL) NOPASSWD: ALL"

if [ -f "$sudoers_file" ] && grep -q "$entry" "$sudoers_file" 2>/dev/null; then
    log_skip "$shell_user already has passwordless sudo"
    exit 0
fi

log_warn "granting passwordless sudo to '$shell_user' (persists until you remove it)"

if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '     [dry-run] would write %s\n' "$sudoers_file"
    exit 0
fi

[ -d "$sudoers_dir" ] || sudo mkdir -p "$sudoers_dir"

# Validate before installing: a malformed sudoers file can lock you out of sudo.
tmp_file="$(mktemp)"
printf '%s\n' "$entry" > "$tmp_file"
if sudo visudo -cf "$tmp_file"; then
    sudo install -m 0440 "$tmp_file" "$sudoers_file"
    log_info "passwordless sudo enabled"
else
    log_error "generated sudoers entry failed validation, not installing"
    rm -f "$tmp_file"
    exit 1
fi
rm -f "$tmp_file"
