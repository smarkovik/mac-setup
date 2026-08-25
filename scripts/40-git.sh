#!/bin/bash
# Global git configuration.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Identity. Override per-machine by exporting GIT_USER_NAME / GIT_USER_EMAIL,
# or just set them yourself - this only fills in what is not already set, so a
# re-run will not stomp an identity you changed by hand.
GIT_USER_NAME="${GIT_USER_NAME:-Tancho Markovik}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-smarkovik@gmail.com}"

set_if_unset() {
    local key="$1" value="$2" existing
    existing="$(git config --global --get "$key" 2>/dev/null || true)"
    if [ -n "$existing" ]; then
        log_skip "git $key already set to '$existing'"
        return 0
    fi
    log_info "setting git $key"
    run git config --global "$key" "$value"
}

set_always() {
    local key="$1" value="$2" existing
    existing="$(git config --global --get "$key" 2>/dev/null || true)"
    if [ "$existing" = "$value" ]; then
        return 0
    fi
    log_info "setting git $key = $value"
    run git config --global "$key" "$value"
}

set_if_unset user.name  "$GIT_USER_NAME"
set_if_unset user.email "$GIT_USER_EMAIL"

set_always apply.whitespace nowarn
set_always pager.branch     false
set_always color.ui         auto
set_always core.editor      nano
