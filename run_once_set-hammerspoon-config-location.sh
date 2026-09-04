#!/bin/bash
set -euo pipefail

# Hammerspoon expands the ~ itself, so the stored value stays portable.
CONFIG="~/.config/hammerspoon/init.lua"

if [ "$(defaults read org.hammerspoon.Hammerspoon MJConfigFile 2>/dev/null || true)" != "$CONFIG" ]; then
  defaults write org.hammerspoon.Hammerspoon MJConfigFile "$CONFIG"
fi
