#!/bin/bash
set -euo pipefail

# Trackpad
defaults write -g com.apple.trackpad.scaling -float 3.0
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false

# Keyboard: fast key repeat, medium-short initial delay
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 30

# Apply preference changes without logout (private framework binary; guard its existence)
ACTIVATE="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
[ -x "$ACTIVATE" ] && "$ACTIVATE" -u
