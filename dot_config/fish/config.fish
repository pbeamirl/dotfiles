# fish ships a default welcome banner; silence it
set -g fish_greeting

# Homebrew (macOS only; Linux gets its environment from nix)
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# ~/.local/bin (user-installed tools)
fish_add_path --global $HOME/.local/bin

# Prompt (starship comes from brew on macOS, nix on Linux)
if status is-interactive; and type -q starship
    starship init fish | source
end
