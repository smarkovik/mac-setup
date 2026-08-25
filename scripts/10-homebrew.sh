#!/bin/bash
# Install Homebrew if missing and put it on PATH for this process.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Apple Silicon prefix. On Intel this would be /usr/local.
BREW_BIN=/opt/homebrew/bin/brew

if have brew; then
    log_skip "Homebrew already installed"
elif [ "${DRY_RUN:-0}" = "1" ]; then
    # NOTE: do not wrap this in `run`. The command substitution would be
    # expanded before `run` ever saw it, so a dry run would fetch and print
    # the entire installer.
    printf '     [dry-run] would install Homebrew via the official install.sh\n'
else
    log_info "Homebrew not present, installing (its installer handles the Command Line Tools)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ "${DRY_RUN:-0}" = "1" ] && [ ! -x "$BREW_BIN" ]; then
    printf '     [dry-run] would configure %s in ~/.zprofile\n' "$BREW_BIN"
    return 0 2>/dev/null || exit 0
fi

if [ ! -x "$BREW_BIN" ]; then
    log_error "Homebrew not found at $BREW_BIN after install"
    exit 1
fi

# Persist brew on PATH for future shells, exactly once.
shellenv_line="eval \"\$($BREW_BIN shellenv)\""
if grep -qxF "$shellenv_line" "$HOME/.zprofile" 2>/dev/null; then
    log_skip "$HOME/.zprofile already sources brew shellenv"
else
    log_info "adding brew shellenv to ~/.zprofile"
    run bash -c "printf '%s\n' '$shellenv_line' >> '$HOME/.zprofile'"
fi

# ...and for the rest of this run.
eval "$($BREW_BIN shellenv)"
