# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Dotfiles managed by **chezmoi**, applied on both Mac and Linux. The repo root is the chezmoi source directory (a non-default location, persisted in `~/.config/chezmoi/chezmoi.toml` by `.chezmoi.toml.tmpl`).

Division of labor with the sibling `../nix-config` (a NixOS flake for the Linux machines):

- **All installation on Linux/NixOS happens in nix-config — this repo never installs anything on Linux.**
- Package installation here is brew-only, macOS-only: packages go in `Brewfile`, and every install script is wrapped in a `{{ if eq .chezmoi.os "darwin" }}` guard.
- This repo owns app configs.

**Direction (not done yet):** nvim, fish, ghostty, and Emacs configs will migrate here out of nix-config, one at a time. Until a given config has migrated, don't duplicate what home-manager still owns.

## Commands

```sh
chezmoi apply       # apply source state to $HOME (also runs pending scripts)
chezmoi diff        # what apply would change — the main "am I in sync" check
chezmoi add <file>  # bring an existing file in $HOME under management

# Bootstrap on a new machine (one time; persists sourceDir):
chezmoi init --source ~/Repositories/github.com/unclebeam/dotfiles --apply
```

## Layout

- Repo root = chezmoi source root. App configs live under `dot_config/<app>/` (→ `~/.config/<app>/`).
- `dot_claude/` → `~/.claude/` (user-level `CLAUDE.md`, `settings.json`, and `executable_statusline.sh` — the Claude Code status line; Mac-only via `.chezmoiignore` while nix-config still owns it on Linux). Claude Code edits `settings.json` itself (`/model`, `/config`); after that, run `chezmoi re-add ~/.claude/settings.json` to sync the change back here.
- `Brewfile` — the single list of brew-managed packages (macOS). Adding a package = one line here; `run_onchange_install-packages.sh.tmpl` re-runs `brew bundle` when it changes.
- `run_once_*` / `run_onchange_*` scripts — setup steps chezmoi runs for us.
- `.chezmoiignore` — repo-only files (README, this file, Brewfile) that must not be applied to `$HOME`; add new repo-only files there.

## Principles

- **Installation is brew-only, macOS-only.** Never add apt/nix/other installers here; on Linux, packages come exclusively from nix-config.
- **Idempotent by construction.** Lean on tools that already are: `brew bundle` skips installed packages — never `brew install` in scripts. Any `run_*` script must check current state before mutating (see `run_once_set-default-shell.sh.tmpl`).
- **Cross-platform by default.** OS-specific behavior goes behind `{{ if eq .chezmoi.os "darwin" }}` in templates, or runtime checks in shell configs (`if test -x /opt/homebrew/bin/brew`). Shared configs must not assume mac paths.
- **Keep it simple.** No wrapper scripts around chezmoi or brew; the flat layout above is the whole structure.

## Workflow

1. Claude edits source files in this repo (never runs `chezmoi apply`, never touches git state).
2. Claude runs `chezmoi diff` and reports what would change.
3. The user runs `chezmoi apply` themselves and verifies the result.
4. Once the user confirms, Claude proposes the exact `git commit` / `git push` commands, waits for a yes, then runs them.
