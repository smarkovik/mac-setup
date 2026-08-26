#!/bin/bash
#
# mac-setup - provision this Mac, repeatably.
#
# Every step is idempotent: run it as often as you like. Steps that have
# nothing to do say so and exit.
#
#   ./mac-setup.sh                      run every default step
#   ./mac-setup.sh --dry-run            show what would happen, change nothing
#   ./mac-setup.sh --list               list the steps
#   ./mac-setup.sh --only macos-defaults [--only git ...]
#   ./mac-setup.sh --force              re-apply settings even where they match
#
# -E so the ERR trap below is inherited by functions and subshells.
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/scripts/lib.sh"

# Ordered. Name -> script. Anything not listed here (e.g. passwordless-sudo)
# is opt-in via --only.
STEP_NAMES=(homebrew packages python dirs git ssh zsh macos-defaults)

step_script() {
    case "$1" in
        homebrew)          echo "10-homebrew.sh" ;;
        packages)          echo "20-packages.sh" ;;
        python)            echo "25-python.sh" ;;
        dirs)              echo "30-dirs.sh" ;;
        git)               echo "40-git.sh" ;;
        ssh)               echo "50-ssh.sh" ;;
        zsh)               echo "60-zsh.sh" ;;
        macos-defaults)    echo "70-macos-defaults.sh" ;;
        passwordless-sudo) echo "90-passwordless-sudo.sh" ;;
        *)                 return 1 ;;
    esac
}

usage() {
    # Print the header comment block, stopping at the first non-comment line.
    awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
}

export DRY_RUN=0
export FORCE=0
ONLY=()

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --force)   FORCE=1 ;;
        --list)
            printf 'default steps:\n'
            for s in "${STEP_NAMES[@]}"; do printf '  %s\n' "$s"; done
            printf 'opt-in steps:\n  passwordless-sudo\n'
            exit 0
            ;;
        --only)
            shift
            [ $# -gt 0 ] || { log_error "--only needs a step name"; exit 2; }
            step_script "$1" >/dev/null || { log_error "unknown step: $1"; exit 2; }
            ONLY+=("$1")
            ;;
        -h|--help) usage; exit 0 ;;
        *) log_error "unknown option: $1"; usage; exit 2 ;;
    esac
    shift
done

if [ "${#ONLY[@]}" -gt 0 ]; then
    STEPS=("${ONLY[@]}")
else
    STEPS=("${STEP_NAMES[@]}")
fi

[ "$DRY_RUN" = "1" ] && log_warn "dry run - nothing will be changed"

# Report which step died rather than just exiting silently under `set -e`.
# Steps are independently re-runnable, so the useful thing to tell you is how
# to resume from the one that broke.
CURRENT_STEP=""
on_failure() {
    local rc=$?
    if [ -n "$CURRENT_STEP" ]; then
        printf '\n'
        log_error "step '$CURRENT_STEP' failed (exit $rc)"
        log_error "once it is fixed, re-run just that step:"
        log_error "    ./mac-setup.sh --only $CURRENT_STEP"
    fi
    exit "$rc"
}
trap on_failure ERR

for name in "${STEPS[@]}"; do
    script="$REPO_DIR/scripts/$(step_script "$name")"
    if [ ! -f "$script" ]; then
        log_error "missing step script: $script"
        exit 1
    fi
    CURRENT_STEP="$name"
    log_step "$name"
    bash "$script"
done

CURRENT_STEP=""
log_info "done"
