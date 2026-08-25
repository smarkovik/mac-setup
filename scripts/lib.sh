#!/bin/bash
# Shared helpers for every step script. Sourced, not executed.

# --- colours -----------------------------------------------------------------
NOCOLOR='\033[0m'
ORANGE='\033[0;33m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'

# NOTE: printf '%b', not echo. Plain bash `echo` prints \033 literally.
log_info()  { printf '%b\n' "${LIGHTGREEN} ===> $1 ${NOCOLOR}"; }
log_warn()  { printf '%b\n' "${ORANGE} ===> $1 ${NOCOLOR}"; }
log_error() { printf '%b\n' "${LIGHTRED} ===> $1 ${NOCOLOR}" >&2; }
log_step()  { printf '%b\n' "${LIGHTBLUE}==> $1${NOCOLOR}"; }
log_skip()  { printf '%b\n' "     (unchanged) $1"; }

# --- dry run -----------------------------------------------------------------
# DRY_RUN is exported by mac-setup.sh. Wrap any command with side effects in
# `run` so --dry-run stays honest.
run() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- change stamps -----------------------------------------------------------
# A step that is expensive or disruptive to repeat (restarting Finder, say) can
# stamp its own source file. If the file has not changed since the last
# successful run, the step can skip itself and report "unchanged" - which is the
# signal that makes this safe to run on a loop.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mac-setup"

stamp_current() { shasum -a 256 "$1" | awk '{print $1}'; }

stamp_is_fresh() {
    # $1 = file to fingerprint, $2 = stamp name
    [ "${FORCE:-0}" = "1" ] && return 1
    local stamp_file="$STATE_DIR/$2.stamp"
    [ -f "$stamp_file" ] || return 1
    [ "$(cat "$stamp_file")" = "$(stamp_current "$1")" ]
}

stamp_write() {
    # $1 = file to fingerprint, $2 = stamp name
    [ "${DRY_RUN:-0}" = "1" ] && return 0
    mkdir -p "$STATE_DIR"
    stamp_current "$1" > "$STATE_DIR/$2.stamp"
}
