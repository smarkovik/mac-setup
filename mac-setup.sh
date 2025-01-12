#!/bin/sh 

# exit on error
set -e
# Xcode location on disk 
XCODE_BIN=/usr/bin
# USER=$(whoami) // system defined


CURRET_DIR=$(pwd)

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

log_info(){
    echo "${LIGHTGREEN} ===> $1 ${NOCOLOR}"
}
log_warn(){
    echo "${ORANGE} ===> $1 ${NOCOLOR}"
}
log_error(){
    echo "${LIGHTRED} ===> $1 ${NOCOLOR}"
}
# Check for user required information needed for ansible
printf "\n\n"

if [ ! -f $CURRET_DIR/tancho.yml ]; then
    log_error "Ansible playbook not found, aborting! \n     (No changes were applied to the system)"
    exit -1
fi
log_info "ansible playbook found: tancho.yml"
log_warn "Checking for XCode install"
xcodebuild -runFirstLaunch
#$XCODE_BIN/xcodebuild -version

#add passwordless sudo 

# Find the currently logged-in user
shell_user=$(whoami)
# Ensure sudoers.d directory exists
sudoers_dir="/private/etc/sudoers.d"
if [ ! -d "$sudoers_dir" ]; then
  echo "Creating sudoers.d directory..."
  mkdir -p "$sudoers_dir"
fi
# Create the sudoers file for the user
sudoers_file="$sudoers_dir/$shell_user"

if [ -f "$sudoers_file" ]; then
  # Check if the user already has the "NOPASSWD" entry
  if grep -q "$shell_user ALL=(ALL) NOPASSWD: ALL" "$sudoers_file"; then
    echo "The user '$shell_user' already has passwordless sudo privileges."
  else
    echo "The sudoers file exists, but it does not have passwordless sudo for '$shell_user'."
    echo "$shell_user ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
    # Set the correct permissions for the sudoers file
    chmod 0440 "$sudoers_file"
  fi
fi

log_warn "Accepting Xcode License if not accepted already (SUDO action, will require password)"
sudo $XCODE_BIN/xcodebuild -license accept

log_warn "installing Rosetta"
softwareupdate --install-rosetta

log_warn "Validating local Homebrew, Ansible installs, (installing if not available ) "

command -v brew >/dev/null 2>&1 || { \
echo >&2 "Homebrew not present on system, installing... "; \
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
}

#setup home-brew
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$USER/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

command -v ansible >/dev/null 2>&1 || { \
echo >&2 "Ansible not present on the system, installing"; \
brew install ansible; \
}

printf "Brew and Ansible already present or freshly installed, moving on. \n"

log_info "running the ansible playbook"
ansible-playbook $CURRET_DIR/tancho.yml

log_info "generating SSH key for github"
ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -q -P ""
echo "paste this in github.com/setting/sshkeys"
cat $HOME/.ssh/id_rsa.pub

log_warn "Looking for oh-my-zsh..."
ohmyzsh='.oh-my-zs'
if [[ $ZSH == *"$ohmyzsh"* ]]; then
    echo "ZSH is alredy there, skipping install"
else
    log_info "installing oh my zsh"
    /bin/sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

