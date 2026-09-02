#!/bin/sh
# PreToolUse(Bash) guard: ask before a git command sweeps up a Claude Code settings file.
#
# Claude Code rewrites its settings.json itself (/model, /config); those edits reach
# this repo via `chezmoi re-add` and are not always meant to sync across devices.
# One file per account profile — see dot_zshrc for the routing.
# Never block on error — a broken guard must not stand between the user and a commit.

TARGETS='dot_claude/settings.json dot_claude-7peaks/settings.json'

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

case "$cmd" in
  *"git commit"*|*"git add"*) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
# Unquoted $TARGETS on purpose: word-split into one pathspec per file.
[ -n "$(git status --porcelain -- $TARGETS 2>/dev/null)" ] || exit 0

staged=$(git diff --cached --name-only -- $TARGETS 2>/dev/null)
modified=$(git diff --name-only -- $TARGETS 2>/dev/null)

included=no
case "$cmd" in
  *"git commit"*)
    [ -n "$staged" ] && included=yes
    case "$cmd" in
      *" -a"*|*" --all"*) [ -n "$modified" ] && included=yes ;;
    esac
    ;;
esac
case "$cmd" in
  *"git add"*)
    case "$cmd" in
      *dot_claude*|*" -A"*|*" --all"*|*" -u"*|*" .") included=yes ;;
      *" . "*) included=yes ;;
    esac
    ;;
esac
[ "$included" = yes ] || exit 0

# Brace ${dirty}: a bare $dirty next to a multi-byte character gets swallowed
# into the variable name by macOS /bin/sh.
dirty=$(git status --porcelain -- $TARGETS 2>/dev/null | awk '{print $NF}' | tr '\n' ' ' | sed 's/ *$//')
diff=$(git diff HEAD -- $TARGETS 2>/dev/null)
reason=$(printf '%s\n\n%s\n\n%s' \
  "This git command includes Claude Code settings that Claude Code edits on its own (/model, /config), so the change may be machine-local rather than something to sync across devices: ${dirty}" \
  "$diff" \
  "Approve to commit it as-is. Reject to leave it out (e.g. \`git restore ${dirty}\`, or commit the other paths explicitly).")

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $r
  }
}'
