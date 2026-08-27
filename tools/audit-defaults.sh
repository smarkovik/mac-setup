#!/bin/bash
#
# Find out which preference key macOS actually uses for a setting.
#
#     ./tools/audit-defaults.sh            # watch every domain we touch
#     ./tools/audit-defaults.sh com.apple.controlcenter com.apple.dock
#
# It snapshots the domains, waits while you change ONE thing in System
# Settings, then diffs and names the key that moved.
#
# Why this exists: `defaults write` succeeds against a key nothing reads, so a
# setting can be dead for years without any error. The preference-key surface
# drifts across macOS releases - com.apple.menuextra.battery ShowPercent was
# still in this repo long after the battery item moved to Control Center in
# Big Sur. Reading the value back cannot detect that; only watching what the
# system itself writes can.
#
# There is no reliable published source for this: macos-defaults.com, the
# reference that tracks per-version compatibility, stops at Sequoia and has no
# macOS 26 data at all. Your machine is the authority.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/scripts/lib.sh"

if ! have defaults; then
    log_error "the 'defaults' command is missing - this tool only runs on macOS"
    exit 1
fi

# Default to the domains the setup step writes to, plus the modern homes that
# settings have migrated into (Control Center swallowed several menu extras).
if [ "$#" -gt 0 ]; then
    DOMAINS=("$@")
else
    # shellcheck disable=SC2207
    DOMAINS=(
        $(grep -oE '^dset (--currentHost )?[A-Za-z0-9.-]+' "$REPO_DIR/scripts/70-macos-defaults.sh" \
            | awk '{print $NF}' | sort -u)
        com.apple.controlcenter
        com.apple.Accessibility
        com.apple.systemuiserver
    )
fi

SNAP_DIR="$(mktemp -d)"
trap 'rm -rf "$SNAP_DIR"' EXIT

snapshot() {
    local into="$1" d
    mkdir -p "$into"
    for d in "${DOMAINS[@]}"; do
        # -g is `defaults`' shorthand for the global domain; keep the filename
        # readable rather than literal.
        local name="${d/#-g/NSGlobalDomain}"
        defaults read "$d" > "$into/$name" 2>/dev/null || true
    done
}

log_info "watching ${#DOMAINS[@]} domains"
snapshot "$SNAP_DIR/before"

cat <<'EOS'

  Now change ONE setting in System Settings (or anywhere in the UI).
  Change exactly one thing - anything else that writes a preference while
  you wait will show up in the diff too.

  Press Return when you have changed it.

EOS
# `|| true` because read returns non-zero at EOF, which under `set -e` would
# kill the script at the prompt when stdin is not a terminal.
read -r _ || true

snapshot "$SNAP_DIR/after"

echo
found=0
for d in "${DOMAINS[@]}"; do
    name="${d/#-g/NSGlobalDomain}"
    b="$SNAP_DIR/before/$name"
    a="$SNAP_DIR/after/$name"
    [ -f "$b" ] || continue

    if ! diff -q "$b" "$a" >/dev/null 2>&1; then
        found=$((found + 1))
        log_info "$d changed:"
        # Show only the changed lines, which is where the key name lives.
        diff "$b" "$a" | grep -E '^[<>]' | sed 's/^/      /' || true
        echo
    fi
done

if [ "$found" -eq 0 ]; then
    log_warn "nothing changed in the watched domains"
    echo "     The setting lives somewhere else. Re-run naming a wider set, e.g.:"
    echo "       ./tools/audit-defaults.sh \$(defaults domains | tr ',' ' ')"
    echo "     (that is every domain on the machine - slower, but exhaustive)"
    exit 0
fi

log_info "$found domain(s) changed - the key above is the one macOS writes today"
