#!/bin/bash

# exit on error
set -e
# Xcode location on disk
XCODE_BIN=/usr/bin

CURRENT_DIR=$(pwd)

#defining bash colors for user input
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# NOTE: use printf '%b' so the \033 escapes above are interpreted.
# Plain `echo` in bash prints them literally.
log_info(){
    printf '%b\n' "${LIGHTGREEN} ===> $1 ${NOCOLOR}"
}
log_warn(){
    printf '%b\n' "${ORANGE} ===> $1 ${NOCOLOR}"
}
log_error(){
    printf '%b\n' "${LIGHTRED} ===> $1 ${NOCOLOR}"
}
# Check for user required information needed for ansible
printf "\n\n"

if [ ! -f "$CURRENT_DIR/tancho.yml" ]; then
    log_error "Ansible playbook not found, aborting! \n     (No changes were applied to the system)"
    exit 1
fi
log_info "ansible playbook found: tancho.yml"

log_warn "Pointing the developer dir at Xcode (SUDO action, will require password)"
# This must happen before any xcodebuild call: if the active developer dir is
# still the Command Line Tools, xcodebuild errors with
# "tool 'xcodebuild' requires Xcode".
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

log_warn "Checking for XCode install"
"$XCODE_BIN/xcodebuild" -runFirstLaunch

#add passwordless sudo 

# Find the currently logged-in user
shell_user=$(whoami)

# Ensure sudoers.d directory exists
sudoers_dir="/private/etc/sudoers.d"
if [ ! -d "$sudoers_dir" ]; then
  echo "Creating sudoers.d directory..."
  sudo mkdir -p "$sudoers_dir"
fi
# Create the sudoers file for the user
sudoers_file="$sudoers_dir/$shell_user"

# Check if the user already has the "NOPASSWD" entry
if [ -f "$sudoers_file" ] && grep -q "$shell_user ALL=(ALL) NOPASSWD: ALL" "$sudoers_file"; then
  echo "The user '$shell_user' already has passwordless sudo privileges."
else
  echo "Granting passwordless sudo for '$shell_user'."
  tmp_sudoers_file=$(mktemp)
  echo "$shell_user ALL=(ALL) NOPASSWD: ALL" > "$tmp_sudoers_file"
  if sudo visudo -cf "$tmp_sudoers_file"; then
    sudo install -m 0440 "$tmp_sudoers_file" "$sudoers_file"
  else
    log_error "Generated sudoers entry failed validation, aborting"
    rm -f "$tmp_sudoers_file"
    exit 1
  fi
  rm -f "$tmp_sudoers_file"
fi

log_warn "Accepting Xcode License if not accepted already (SUDO action, will require password)"
sudo "$XCODE_BIN/xcodebuild" -license accept

#log_warn "installing Rosetta"
#softwareupdate --install-rosetta

log_warn "Validating local Homebrew, Ansible installs, (installing if not available ) "

command -v brew >/dev/null 2>&1 || { \
echo >&2 "Homebrew not present on system, installing... "; \
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
}

#setup home-brew (Apple Silicon prefix)
BREW_BIN=/opt/homebrew/bin/brew
if [ ! -x "$BREW_BIN" ]; then
    log_error "Homebrew not found at $BREW_BIN after install, aborting"
    exit 1
fi
grep -qxF "eval \"\$($BREW_BIN shellenv)\"" "$HOME/.zprofile" 2>/dev/null || \
    echo "eval \"\$($BREW_BIN shellenv)\"" >> "$HOME/.zprofile"
eval "$($BREW_BIN shellenv)"

command -v ansible >/dev/null 2>&1 || { \
echo >&2 "Ansible not present on the system, installing"; \
brew install ansible; \
}

printf "Brew and Ansible already present or freshly installed, moving on. \n"

log_info "running the ansible playbook"
ansible-playbook "$CURRENT_DIR/tancho.yml"

log_info "generating SSH key for github"
if [ -f "$HOME/.ssh/id_rsa" ]; then
    log_warn "SSH key already exists at $HOME/.ssh/id_rsa, skipping generation"
else
    ssh-keygen -t rsa -f "$HOME/.ssh/id_rsa" -q -P ""
fi
echo "paste this in github.com/setting/sshkeys"
cat "$HOME/.ssh/id_rsa.pub"

log_warn "Looking for oh-my-zsh..."
# Check the install dir directly. $ZSH is only set inside an interactive zsh
# session that has already sourced oh-my-zsh, so it is always empty here.
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh is already there, skipping install"
else
    log_info "installing oh my zsh"
    # --unattended stops the installer from running `exec zsh` at the end,
    # which would replace this script's process before it finishes.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

