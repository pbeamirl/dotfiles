#!/bin/sh
# PreToolUse(Bash) guard: ask before a git command sweeps up dot_claude/settings.json.
#
# Claude Code rewrites ~/.claude/settings.json itself (/model, /config); those edits
# reach this repo via `chezmoi re-add` and are not always meant to sync across devices.
# Never block on error — a broken guard must not stand between the user and a commit.

TARGET='dot_claude/settings.json'

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

case "$cmd" in
  *"git commit"*|*"git add"*) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[ -n "$(git status --porcelain -- "$TARGET" 2>/dev/null)" ] || exit 0

staged=$(git diff --cached --name-only -- "$TARGET" 2>/dev/null)
modified=$(git diff --name-only -- "$TARGET" 2>/dev/null)

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

diff=$(git diff HEAD -- "$TARGET" 2>/dev/null)
reason=$(printf '%s\n\n%s\n\n%s' \
  "This git command includes $TARGET, which Claude Code edits on its own (/model, /config) — the change may be machine-local rather than something to sync across devices." \
  "$diff" \
  "Approve to commit it as-is. Reject to leave it out (e.g. \`git restore $TARGET\`, or commit the other paths explicitly).")

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $r
  }
}'
