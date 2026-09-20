#!/bin/bash
#
# mac-setup - provision this Mac, repeatably.
#
# Every step is idempotent: run it as often as you like. Steps that have
# nothing to do say so and exit. A step that fails does not stop the rest -
# it's reported at the end so the run keeps maintaining everything else.
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
STEP_NAMES=(homebrew packages python dirs git ssh zsh opencode macos-defaults local-code)

step_script() {
    case "$1" in
        homebrew)          echo "10-homebrew.sh" ;;
        packages)          echo "20-packages.sh" ;;
        python)            echo "25-python.sh" ;;
        dirs)              echo "30-dirs.sh" ;;
        git)               echo "40-git.sh" ;;
        ssh)               echo "50-ssh.sh" ;;
        zsh)               echo "60-zsh.sh" ;;
        opencode)          echo "65-opencode.sh" ;;
        local-code)        echo "80-local-code.sh" ;;
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

# A failing step must not stop the ones after it. This is meant to be run
# unattended, repeatedly, as the thing that keeps a machine maintained over
# time - one broken cask or a settings domain that needs an interactive
# prompt should not block dirs/git/ssh/zsh/opencode from doing their job.
# Steps are independently re-runnable, so each failure is collected and
# reported at the end rather than raised immediately.
#
# The `if bash "$script"; then ... else` form matters, and matters in this
# exact shape: a command tested by `if` does not trigger `set -e`, so one
# step failing here does not raise like an untested command would. Using
# `if ! bash "$script"; then` instead would be wrong in a different way -
# `!` negates $?, so the "then" branch would see exit 0/1 from the negation,
# not the step's real exit code.
FAILED_STEPS=()

# Kept only for genuinely unexpected failures in this orchestrator itself
# (not step scripts, which are handled explicitly below and never reach it).
on_failure() {
    local rc=$?
    log_error "mac-setup.sh failed unexpectedly (exit $rc)"
    exit "$rc"
}
trap on_failure ERR

# So a long silent stretch (a slow cask download, a source build) reads as
# "step 3/10, running" rather than an unlabeled wall of scrolling output.
TOTAL_STEPS="${#STEPS[@]}"
STEP_NUM=0
RUN_START_EPOCH=$(date +%s)

for name in "${STEPS[@]}"; do
    STEP_NUM=$((STEP_NUM + 1))
    script="$REPO_DIR/scripts/$(step_script "$name")"
    if [ ! -f "$script" ]; then
        log_error "missing step script: $script"
        FAILED_STEPS+=("$name")
        continue
    fi
    log_step "[$STEP_NUM/$TOTAL_STEPS] $name"
    # SECONDS is a bash builtin counting up from the last assignment - no
    # `date` subprocess needed, and it works the same on bash 3.2.
    SECONDS=0
    if bash "$script"; then
        log_info "$name done (${SECONDS}s)"
    else
        rc=$?
        FAILED_STEPS+=("$name")
        printf '\n'
        log_error "step '$name' failed after ${SECONDS}s (exit $rc) - continuing with the remaining steps"
        log_error "once it is fixed, re-run just that step:"
        log_error "    ./mac-setup.sh --only $name"
        printf '\n'
    fi
done

TOTAL_ELAPSED=$(( $(date +%s) - RUN_START_EPOCH ))

if [ "${#FAILED_STEPS[@]}" -gt 0 ]; then
    printf '\n'
    log_error "finished in ${TOTAL_ELAPSED}s with ${#FAILED_STEPS[@]} step(s) needing attention:"
    for name in "${FAILED_STEPS[@]}"; do
        log_error "  - $name (re-run: ./mac-setup.sh --only $name)"
    done
    exit 1
fi

log_info "done (${TOTAL_ELAPSED}s)"
