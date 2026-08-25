#!/bin/bash
# Home folder structure.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DIRS=(
    "$HOME/bin"
    "$HOME/Development/repos"
    "$HOME/Development/bin"
    "$HOME/Development/tools"
    "$HOME/Development/tests"
    "$HOME/Pictures/Screenshots"
)

created=0
for d in "${DIRS[@]}"; do
    if [ -d "$d" ]; then
        continue
    fi
    log_info "creating $d"
    run mkdir -p "$d"
    created=$((created + 1))
done

[ "$created" -eq 0 ] && log_skip "all directories already present"
exit 0
