#!/bin/bash
# Make Homebrew's CPython the one you get system-wide, not Apple's.
#
# Two separate things are going on:
#
#   python3 - Homebrew links this into /opt/homebrew/bin, which the shellenv
#             line puts ahead of /usr/bin on PATH, so `python3` already
#             resolves to Homebrew's. Nothing to do.
#
#   python  - Homebrew deliberately does NOT link an unversioned `python` or
#             `pip`. They live in the formula's libexec/bin. Adding that
#             directory is what makes plain `python` and `pip` work, and is
#             Homebrew's documented way to do it.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! have brew; then
    # On a fresh machine a --dry-run has not actually installed brew, so this
    # is expected rather than an error: report and move on.
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] brew not present yet; would configure python PATH after the packages step\n'
        exit 0
    fi
    log_error "brew not on PATH - run the homebrew step first"
    exit 1
fi

if ! brew list --formula python >/dev/null 2>&1 && ! brew list --formula python@3 >/dev/null 2>&1; then
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] python not installed yet; would configure PATH after the packages step\n'
        exit 0
    fi
    log_error "Homebrew python is not installed - run the packages step first"
    exit 1
fi

# Resolve through the alias rather than hardcoding a version, so this keeps
# working when Homebrew moves `python` to the next release.
PY_PREFIX="$(brew --prefix python)"
LIBEXEC_BIN="$PY_PREFIX/libexec/bin"

if [ ! -d "$LIBEXEC_BIN" ]; then
    log_warn "expected $LIBEXEC_BIN to exist; skipping unversioned python setup"
    exit 0
fi

path_line="export PATH=\"$LIBEXEC_BIN:\$PATH\""

if grep -qxF "$path_line" "$HOME/.zprofile" 2>/dev/null; then
    log_skip "$HOME/.zprofile already puts Homebrew python first"
else
    log_info "adding Homebrew python to PATH in ~/.zprofile"
    run bash -c "printf '%s\n' '$path_line' >> '$HOME/.zprofile'"
fi

if [ "${DRY_RUN:-0}" != "1" ]; then
    export PATH="$LIBEXEC_BIN:$PATH"
    log_info "python  -> $(command -v python 2>/dev/null || echo 'not found') ($(python --version 2>&1))"
    log_info "python3 -> $(command -v python3 2>/dev/null || echo 'not found') ($(python3 --version 2>&1))"
    log_warn "Apple's is /usr/bin/python3 - open a new shell for the change to apply everywhere"
fi
