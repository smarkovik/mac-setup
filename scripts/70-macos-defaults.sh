#!/bin/bash
# macOS UI preferences.
#
# Applying these is cheap, but restarting Dock/Finder/SystemUIServer is not:
# it closes your Finder windows. So this script fingerprints itself and skips
# entirely when nothing in it has changed since the last successful run.
# Use --force to re-apply anyway.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SELF="${BASH_SOURCE[0]}"

if stamp_is_fresh "$SELF" "macos-defaults"; then
    log_skip "macOS defaults unchanged since last run"
    exit 0
fi

log_info "applying macOS defaults"

if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '     [dry-run] would apply the defaults in %s and restart Dock/Finder/SystemUIServer\n' "$SELF"
    exit 0
fi

# show Library folder
chflags nohidden ~/Library

# --- Finder ------------------------------------------------------------------
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder QLEnableTextSelection -bool true
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder PathBarRootAtHome -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Use list view in all Finder windows by default.
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Set Home folder as the default location for new Finder windows.
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# --- global ------------------------------------------------------------------
# NOTE: `-g` and `NSGlobalDomain` are the same domain.
defaults write -g AppleShowAllExtensions -bool true
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSWindowSupportsAutomaticInlineTitle -bool false

# Disable the text substitutions that get in the way when typing code
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# Disable press-and-hold for keys in favor of key repeat
defaults write -g ApplePressAndHoldEnabled -bool false

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
defaults write -g AppleKeyboardUIMode -int 3

# Language and text formats
defaults write -g AppleLanguages -array "en" "mk" "fr"
defaults write -g AppleLocale -string "en_GB@currency=EUR"
defaults write -g AppleMeasurementUnits -string "Centimeters"
defaults write -g AppleMetricUnits -bool true

# --- screenshots -------------------------------------------------------------
defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"

# --- Dock --------------------------------------------------------------------
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock expose-animation-duration -float 0.12
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock show-recents -bool false

# NOTE: -array-add APPENDS, so running this repeatedly stacks up duplicate
# tiles. Only add the recents tile if it is not there yet.
if ! defaults read com.apple.dock persistent-others 2>/dev/null | grep -q 'recents-tile'; then
    defaults write com.apple.dock persistent-others -array-add \
        '{ "tile-data" = { "list-type" = 1; }; "tile-type" = "recents-tile"; }'
fi

# --- menu bar ----------------------------------------------------------------
defaults write com.apple.menuextra.battery ShowPercent -bool true

# --- network -----------------------------------------------------------------
# Enable AirDrop over Ethernet
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# --- desktop services --------------------------------------------------------
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true

# --- input -------------------------------------------------------------------
# Trackpad: tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1

# Follow the keyboard focus while zoomed in
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# --- misc apps ---------------------------------------------------------------
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
defaults write com.microsoft.Office SendPersonalInformationToMotherShip -bool false

# TextEdit: plain text, UTF-8
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# --- restart affected apps ---------------------------------------------------
# `|| true` because killall exits non-zero when the process is not running.
for app in Dock Finder SystemUIServer; do
    killall "$app" >/dev/null 2>&1 || true
done

stamp_write "$SELF" "macos-defaults"
log_info "macOS defaults applied"
