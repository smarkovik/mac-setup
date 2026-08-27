#!/bin/bash
# macOS UI preferences.
#
# Every setting is compared against its live value and written only if it
# differs. That means this converges rather than merely not-repeating: a
# preference you changed in System Settings gets put back on the next run.
#
# Dock/Finder/SystemUIServer are restarted only when something actually
# changed, so a run with no drift closes none of your Finder windows.
#
# --force rewrites everything regardless of current value.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! have defaults; then
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] not macOS - would apply the defaults in this step\n'
        exit 0
    fi
    log_error "the 'defaults' command is missing - this step only runs on macOS"
    exit 1
fi

# show Library folder (cheap, no restart needed, not counted as a change)
chflags nohidden ~/Library 2>/dev/null || true

# --- Finder ------------------------------------------------------------------
dset com.apple.finder _FXSortFoldersFirst -bool true
dset com.apple.finder _FXShowPosixPathInTitle -bool true
dset com.apple.finder AppleShowAllFiles -bool true
dset com.apple.finder QLEnableTextSelection -bool true
dset com.apple.finder ShowRecentTags -bool false
dset com.apple.finder PathBarRootAtHome -bool true
dset com.apple.finder ShowStatusBar -bool true
dset com.apple.finder ShowPathbar -bool true
dset com.apple.finder FXEnableExtensionChangeWarning -bool false
dset com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Use list view in all Finder windows by default.
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
dset com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Set Home folder as the default location for new Finder windows.
# For other paths, use `PfLo` and `file:///full/path/here/`
dset com.apple.finder NewWindowTarget -string "PfDe"
dset com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# --- global ------------------------------------------------------------------
# NOTE: `-g` and `NSGlobalDomain` are the same domain.
dset -g AppleShowAllExtensions -bool true
dset -g NSDocumentSaveNewDocumentsToCloud -bool false
dset -g NSNavPanelExpandedStateForSaveMode -bool true
dset -g NSWindowSupportsAutomaticInlineTitle -bool false

# Disable the text substitutions that get in the way when typing code
dset -g NSAutomaticCapitalizationEnabled -bool false
dset -g NSAutomaticDashSubstitutionEnabled -bool false
dset -g NSAutomaticPeriodSubstitutionEnabled -bool false
dset -g NSAutomaticQuoteSubstitutionEnabled -bool false
dset -g NSAutomaticSpellingCorrectionEnabled -bool false

# Disable press-and-hold for keys in favor of key repeat
dset -g ApplePressAndHoldEnabled -bool false

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
dset -g AppleKeyboardUIMode -int 3

# Language and text formats
darray -g AppleLanguages "en" "mk" "fr"
dset -g AppleLocale -string "en_GB@currency=EUR"
dset -g AppleMeasurementUnits -string "Centimeters"
dset -g AppleMetricUnits -bool true

# --- screenshots -------------------------------------------------------------
dset com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
dset com.apple.screencapture type -string "png"

# --- Dock --------------------------------------------------------------------
dset com.apple.dock show-process-indicators -bool true
dset com.apple.dock showhidden -bool true
dset com.apple.dock expose-animation-duration -float 0.12
dset com.apple.dock minimize-to-application -bool true
dset com.apple.dock orientation -string left
dset com.apple.dock show-recents -bool false

# NOTE: -array-add APPENDS, so running this repeatedly stacks up duplicate
# tiles. Only add the recents tile if it is not there yet.
if ! defaults read com.apple.dock persistent-others 2>/dev/null | grep -q 'recents-tile'; then
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '     [dry-run] would add the recents tile to the Dock\n'
    else
        log_info "com.apple.dock persistent-others += recents-tile"
        defaults write com.apple.dock persistent-others -array-add \
            '{ "tile-data" = { "list-type" = 1; }; "tile-type" = "recents-tile"; }'
    fi
    DEFAULTS_CHANGED=$((DEFAULTS_CHANGED + 1))
fi

# --- network -----------------------------------------------------------------
# Enable AirDrop over Ethernet
dset com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# --- desktop services --------------------------------------------------------
# Avoid creating .DS_Store files on network or USB volumes
dset com.apple.desktopservices DSDontWriteUSBStores -bool true
dset com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Automatically open a new Finder window when a volume is mounted
dset com.apple.frameworks.diskimages auto-open-ro-root -bool true
dset com.apple.frameworks.diskimages auto-open-rw-root -bool true

# --- input -------------------------------------------------------------------
# Trackpad: tap to click
dset com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
dset --currentHost -g com.apple.mouse.tapBehavior -int 1
dset -g com.apple.mouse.tapBehavior -int 1

# Follow the keyboard focus while zoomed in
dset com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# --- misc apps ---------------------------------------------------------------
dset com.apple.print.PrintingPrefs "Quit When Finished" -bool true
dset com.apple.mail AddressesIncludeNameOnPasteboard -bool false
dset com.microsoft.Office SendPersonalInformationToMotherShip -bool false

# TextEdit: plain text, UTF-8
dset com.apple.TextEdit RichText -int 0
dset com.apple.TextEdit PlainTextEncoding -int 4
dset com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Activity Monitor
dset com.apple.ActivityMonitor OpenMainWindow -bool true
dset com.apple.ActivityMonitor IconType -int 5
dset com.apple.ActivityMonitor ShowCategory -int 0
dset com.apple.ActivityMonitor SortColumn -string "CPUUsage"
dset com.apple.ActivityMonitor SortDirection -int 0

# --- legacy / no longer effective --------------------------------------------
# These were in the original playbook. I believe each is now a no-op on current
# macOS, so they are kept here, disabled, with the reason - rather than deleted
# silently. Verify before re-enabling; if one still works for you, move it up.
#
#   # Safari's preferences are TCC-protected since Mojave. `defaults write`
#   # against com.apple.Safari silently does nothing unless the terminal has
#   # Full Disk Access.
#   dset com.apple.Safari UniversalSearchEnabled -bool false
#   dset com.apple.Safari SuppressSearchSuggestions -bool true
#   dset com.apple.Safari SendDoNotTrackHTTPHeader -bool true
#
#   # Screen-saver password settings moved to a protected domain; setting them
#   # via `defaults` no longer takes effect. Use System Settings > Lock Screen.
#   dset com.apple.screensaver askForPassword -int 1
#   dset com.apple.screensaver askForPasswordDelay -int 0
#
#   # Subpixel antialiasing was removed in Mojave; this key does nothing.
#   dset -g AppleFontSmoothing -int 1
#
#   # The whole com.apple.menuextra.battery domain died when the battery item
#   # moved to Control Center in Big Sur. Neither key is read any more - set
#   # this in System Settings > Control Center > Battery > Show Percentage.
#   # (ShowPercent was left active here until an audit caught that it sits in
#   # the same dead domain as ShowTime.)
#   dset com.apple.menuextra.battery ShowTime -bool true
#   dset com.apple.menuextra.battery ShowPercent -bool true
#
#   # This key predates AAC/LDAC negotiation on modern macOS and no longer
#   # affects Bluetooth audio quality.
#   dset com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
#
#   # Dashboard was removed in Catalina.
#   dset com.apple.dashboard devmode -bool true
#
#   # Secure Empty Trash was removed when APFS shipped.
#   dset com.apple.finder EmptyTrashSecurely -bool true
#
#   # menuExtras has had no effect since Big Sur moved the menu bar to
#   # Control Center.
#   darray com.apple.systemuiserver menuExtras ...

# --- restart affected apps, only if something changed ------------------------
if [ "$DEFAULTS_CHANGED" -eq 0 ]; then
    log_skip "all macOS defaults already match - nothing restarted"
    exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '     [dry-run] %s setting(s) differ; would restart Dock/Finder/SystemUIServer\n' \
        "$DEFAULTS_CHANGED"
    exit 0
fi

log_info "$DEFAULTS_CHANGED setting(s) changed, restarting Dock/Finder/SystemUIServer"
# `|| true` because killall exits non-zero when the process is not running.
for app in Dock Finder SystemUIServer; do
    killall "$app" >/dev/null 2>&1 || true
done
