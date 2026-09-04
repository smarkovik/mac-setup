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

# --- macOS defaults ----------------------------------------------------------
# Compare each setting against its live value and write only what differs.
#
# This is what makes the defaults step converge rather than merely not-repeat:
# a setting you changed in System Settings gets put back, and a run where
# nothing drifted touches nothing - so the Dock/Finder restart can be skipped.
#
# DEFAULTS_CHANGED counts the writes actually performed. Callers restart the
# affected apps only when it is non-zero.
DEFAULTS_CHANGED=0

# `defaults read` normalises what it returns, so the value written and the
# value read back are not always the same string. Map write-value -> read-value.
_dread_expect() {
    local flag="$1" value="$2"
    case "$flag" in
        -bool)
            case "$value" in
                true|TRUE|yes|YES|1) printf '1' ;;
                *)                   printf '0' ;;
            esac
            ;;
        *) printf '%s' "$value" ;;
    esac
}

# Run `defaults`, optionally with -currentHost.
#
# NOTE: deliberately not an array of extra args. macOS ships bash 3.2, where
# expanding an EMPTY array as "${arr[@]}" under `set -u` is an unbound-variable
# error (fixed in bash 4.4). That construct aborted this script on the macOS
# runner before it wrote a single setting, while working fine on bash 5 locally.
_defaults() {
    local ch="$1"
    shift
    if [ "$ch" = "1" ]; then
        defaults -currentHost "$@"
    else
        defaults "$@"
    fi
}

# dset [--currentHost] <domain> <key> <flag> <value>
#   flag: -bool | -int | -float | -string
dset() {
    local ch=0
    if [ "$1" = "--currentHost" ]; then ch=1; shift; fi
    local domain="$1" key="$2" flag="$3" value="$4"

    local want have
    want="$(_dread_expect "$flag" "$value")"
    have="$(_defaults "$ch" read "$domain" "$key" 2>/dev/null || true)"

    if [ "${FORCE:-0}" != "1" ]; then
        if [ "$flag" = "-float" ] && [ -n "$have" ]; then
            # Floats can read back with extra precision, so compare numerically.
            if awk -v a="$have" -v b="$want" 'BEGIN { exit !(a + 0 == b + 0) }'; then
                return 0
            fi
        elif [ "$have" = "$want" ]; then
            return 0
        fi
    fi

    # Label the -currentHost variant, otherwise a key set both per-host and
    # globally logs as two identical lines and reads like a duplicate.
    local label="$domain"
    [ "$ch" = "1" ] && label="-currentHost $domain"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] would set %s %s = %s\n' "$label" "$key" "$value"
    else
        log_info "$label $key = $value"
        _defaults "$ch" write "$domain" "$key" "$flag" "$value"
    fi
    DEFAULTS_CHANGED=$((DEFAULTS_CHANGED + 1))
}

# darray <domain> <key> <value>...
# `defaults read` prints arrays as a multi-line plist, so flatten both sides
# to a comma-joined string before comparing.
darray() {
    local domain="$1" key="$2"
    shift 2

    local want have
    want="$(IFS=,; printf '%s' "$*")"
    have="$(defaults read "$domain" "$key" 2>/dev/null | tr -d ' \n"' || true)"
    have="${have#(}"
    have="${have%)}"

    if [ "${FORCE:-0}" != "1" ] && [ "$have" = "$want" ]; then
        return 0
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] would set %s %s = %s\n' "$domain" "$key" "$want"
    else
        log_info "$domain $key = $want"
        defaults write "$domain" "$key" -array "$@"
    fi
    DEFAULTS_CHANGED=$((DEFAULTS_CHANGED + 1))
}
