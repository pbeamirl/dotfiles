# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Dotfiles managed by **chezmoi** for two Apple-Silicon Macs: the personal laptop and the 7peaks work laptop. The repo root is the chezmoi source directory (a non-default location, persisted in `~/.config/chezmoi/chezmoi.toml` by `.chezmoi.toml.tmpl`). This repo owns app configs; package installation is brew-only — packages go in `Brewfile`. There are no OS guards: everything here assumes macOS and `/opt/homebrew`.

## Commands

```sh
chezmoi apply       # apply source state to $HOME (also runs pending scripts)
chezmoi diff        # what apply would change — the main "am I in sync" check
chezmoi add <file>  # bring an existing file in $HOME under management

# Bootstrap on a new machine (one time; persists sourceDir):
chezmoi init --source ~/Repositories/github.com/pbeamirl/dotfiles --apply
```

## Layout

- Repo root = chezmoi source root. App configs live under `dot_config/<app>/` (→ `~/.config/<app>/`).
- `dot_claude/` → `~/.claude/` (user-level `CLAUDE.md`, `settings.json`, and `executable_statusline.sh` — the Claude Code status line). Claude Code edits `settings.json` itself (`/model`, `/config`), and herdr's Claude integration adds a `SessionStart` hook pointing at `~/.claude/hooks/herdr-agent-state.sh` (herdr-managed, not in this repo); after either, run `chezmoi re-add ~/.claude/settings.json` to sync the change back here. Because those edits are often machine-local, `.claude/settings.json` registers a `PreToolUse` hook (`.claude/hooks/guard-claude-settings.sh`) that turns any `git commit`/`git add` including either profile's `settings.json` or `dot_claude/CLAUDE.md` into a permission prompt showing its diff.
- `dot_claude-7peaks/` → `~/.claude-7peaks/`, the **7peaks work account's** Claude Code profile. The 7peaks seat is a separate Claude subscription, and Claude Code stores exactly one login per config directory, so the two accounts need two directories. The `claude()` wrapper in `dot_zshrc` sets `CLAUDE_CONFIG_DIR` to this one for anything under `~/Repositories/github.com/7-peaks-software/`, mirroring the per-directory git identity split in `dot_config/git/config`; `claude-personal` (or `CC_ACCOUNT=personal`) opts back out inside a work repo. `settings.json` here is a deliberate copy of its `dot_claude/` counterpart — Claude Code rewrites `settings.json` in place, so it has to stay independently `chezmoi re-add`-able, and the two may legitimately drift. `CLAUDE.md.tmpl` is a one-line `include` of `dot_claude/CLAUDE.md`, so edit that one. `statusline.sh` is *not* copied: both profiles' `settings.json` point at the absolute `~/.claude/statusline.sh`, and that script derives its cache path and Keychain service name from `$CLAUDE_CONFIG_DIR` so each profile reports its own usage.
- `.claude/` — repo-only Claude Code config (the commit guard above). chezmoi skips dot-prefixed source entries, so it is never applied to `$HOME`; do *not* list it in `.chezmoiignore`, whose patterns match target paths and would break the real `~/.claude/settings.json`.
- `dot_config/git/` — `config` holds shared behavior plus the two `includeIf gitdir:` rules; the per-account identities live in `pbeamirl` and `7peaks`. `user.useConfigOnly = true` means a repo matching neither rule refuses to commit rather than guessing an author. `ignore` is the global excludes file (git reads it by default under XDG); Claude Code appends to it, so `chezmoi re-add ~/.config/git/ignore` after it does.
- `Brewfile` — the single list of brew-managed packages. Adding a package = one line here; `run_onchange_install-packages.sh.tmpl` re-runs `brew bundle` when it changes.
- `run_once_*` / `run_onchange_*` scripts — setup steps chezmoi runs for us. Only the ones that use template data keep a `.tmpl` suffix. `run_onchange_install-mise-tools.sh.tmpl` guards on `command -v mise` because run_onchange scripts run alphabetically and it fires before `install-packages` on a fresh machine.
- `.chezmoiignore` — repo-only files (README, this file, Brewfile) that must not be applied to `$HOME`; add new repo-only files there.

## Principles

- **Installation is brew-only.** Never add other installers here; `brew bundle` is the whole story.
- **Idempotent by construction.** Lean on tools that already are: `brew bundle` skips installed packages — never `brew install` in scripts. Any `run_*` script must check current state before mutating (see `run_once_set-default-shell.sh`).
- **macOS-only.** Both machines are Apple-Silicon Macs: hardcode `/opt/homebrew`, use BSD `date`/`stat`, no `{{ if eq .chezmoi.os … }}` guards, no Linux fallbacks.
- **Keep it simple.** No wrapper scripts around chezmoi or brew; the flat layout above is the whole structure.

## Workflow

1. Claude edits source files in this repo (never runs `chezmoi apply`, never touches git state).
2. Claude runs `chezmoi diff` and reports what would change.
3. The user runs `chezmoi apply` themselves and verifies the result.
4. Once the user confirms, Claude proposes the exact `git commit` / `git push` commands, waits for a yes, then runs them. If either profile's `settings.json` or `dot_claude/CLAUDE.md` is dirty, say what changed in it and ask whether to include it before proposing the commit.
