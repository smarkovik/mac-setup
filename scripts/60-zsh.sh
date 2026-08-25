#!/bin/bash
# oh-my-zsh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Check the install dir directly. $ZSH is only set inside an interactive zsh
# session that has already sourced oh-my-zsh, so it is always empty here.
if [ -d "$HOME/.oh-my-zsh" ]; then
    log_skip "oh-my-zsh already installed"
    exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
    # NOTE: do not wrap this in `run`. The command substitution would be
    # expanded before `run` ever saw it, so a dry run would fetch and print
    # the entire installer.
    printf '     [dry-run] would install oh-my-zsh via the official install.sh\n'
    exit 0
fi

log_info "installing oh-my-zsh"
# --unattended stops the installer from running `exec zsh` at the end, which
# would replace this process before the remaining steps run.
/bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
