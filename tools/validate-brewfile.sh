#!/bin/bash
#
# Check that every cask and formula named in the Brewfile actually exists.
#
# This is a development/CI tool, not one of the setup steps - it installs
# nothing. Run it directly, or let CI run it on a macOS runner:
#
#     ./tools/validate-brewfile.sh [path/to/Brewfile]
#
# Why this exists: `brew bundle` fails the ENTIRE file on a single bad token,
# so one typo takes every other package down with it. The repo shipped
# `cask "gitup"` (the real token is "gitup-app") for a long time without
# anyone noticing, because nothing checked.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="${1:-$REPO_DIR/Brewfile}"

if [ ! -f "$BREWFILE" ]; then
    echo "no Brewfile at $BREWFILE" >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "brew not found - this check needs Homebrew (run it on macOS)" >&2
    exit 1
fi

failed=()
checked=0

# `brew info` resolves aliases (e.g. `python` -> python@3.14) and exits
# non-zero on an unknown token, without installing anything.
check() {
    local flag="$1" token="$2"
    checked=$((checked + 1))
    if brew info "$flag" "$token" >/dev/null 2>&1; then
        printf '  ok    %-6s %s\n' "${flag#--}" "$token"
    else
        printf '  FAIL  %-6s %s\n' "${flag#--}" "$token"
        failed+=("${flag#--} $token")
    fi
}

echo "validating $BREWFILE"

while read -r kind token; do
    case "$kind" in
        cask) check --cask "$token" ;;
        brew) check --formula "$token" ;;
    esac
done < <(sed -n 's/^\(cask\|brew\) *"\([^"]*\)".*/\1 \2/p' "$BREWFILE")

echo
if [ "$checked" -eq 0 ]; then
    echo "no entries found in $BREWFILE - is the format right?" >&2
    exit 1
fi

if [ "${#failed[@]}" -gt 0 ]; then
    echo "${#failed[@]} of $checked entries do not exist:" >&2
    printf '  %s\n' "${failed[@]}" >&2
    echo >&2
    echo "brew bundle fails the whole file on any one of these." >&2
    exit 1
fi

echo "all $checked entries resolve"
