#!/bin/bash
set -euo pipefail

ZSH="/bin/zsh"

if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" != "$ZSH" ]; then
  chsh -s "$ZSH"
fi
