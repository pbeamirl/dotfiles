#!/usr/bin/env bash
# Claude Code status line.
#
# Renders one line, left to right:
#   󰧑 ▰▰▰▱▱▱▱▱ 34%                         context window used
#   󰥔 12% → 5:00 PM                        5-hour session limit, reset time
#   󰃭 All 25% · Fable 46% → Sat 8:00 PM    7-day limits (all models / model-scoped), reset
#   󰉋 dotfiles  󰊢 main*                   workspace dir, git branch (* = dirty)
#   Fable 5                                 current model
#
# Input: Claude Code's status-line JSON on stdin. Fields used:
#   .context_window.{used_percentage,context_window_size}, .transcript_path,
#   .rate_limits.{five_hour,seven_day}.{used_percentage,resets_at},
#   .model.display_name, .workspace.current_dir
#
# The stdin JSON only carries the combined `seven_day` weekly figure. The
# model-scoped weekly limit (e.g. Fable) comes from the Anthropic usage API
# (https://api.anthropic.com/api/oauth/usage) using the local OAuth token —
# macOS Keychain first, then ~/.claude/.credentials.json (Linux). The token
# is never printed. Responses are cached for 60s in
# ~/.claude/statusline-usage-cache.json so most renders never hit the network.
#
# Icons are Nerd Font glyphs, written literally because macOS bash 3.2 has no
# $'\U…' escapes; swap or blank them in the ICON_* block below. jq output is
# joined with US (0x1f) rather than tabs because `read` collapses adjacent
# tab delimiters and would shift fields when one is empty.

# --- Appearance ---------------------------------------------------------------
ICON_CTX="󰧑"     # nf-md-brain          U+F09D1
ICON_SESSION="󰥔" # nf-md-clock_outline  U+F0954
ICON_WEEK="󰃭"    # nf-md-calendar       U+F00ED
ICON_DIR="󰉋"     # nf-md-folder         U+F024B
ICON_GIT="󰊢"     # nf-md-source_branch  U+F02A2
BAR_WIDTH=8
BAR_FULL="▰"
BAR_EMPTY="▱"
SEP="  "
US=$'\x1f'

RESET=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'

# --- Input --------------------------------------------------------------------
input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf "statusline: jq not found"
  exit 0
fi

IFS="$US" read -r ctx_pct window_size transcript five_pct five_reset week_pct week_reset model_name cwd < <(
  printf "%s" "$input" | jq -r '
    [ .context_window.used_percentage, .context_window.context_window_size,
      .transcript_path,
      .rate_limits.five_hour.used_percentage, .rate_limits.five_hour.resets_at,
      .rate_limits.seven_day.used_percentage, .rate_limits.seven_day.resets_at,
      .model.display_name, .workspace.current_dir ]
    | map(if . == null then "" else tostring end) | join("\u001f")' 2>/dev/null
)

# --- Helpers ------------------------------------------------------------------
# Threshold color for a percentage: green (<70), yellow (70-89), red (90+).
pct_color() {
  local pct="$1"
  if [ "$pct" -ge 90 ]; then printf "%s" "$RED"
  elif [ "$pct" -ge 70 ]; then printf "%s" "$YELLOW"
  else printf "%s" "$GREEN"
  fi
}

# "34%" colored by threshold.
color_pct() {
  local pct
  pct=$(printf "%.0f" "$1" 2>/dev/null) || return
  printf "%s%s%%%s" "$(pct_color "$pct")" "$pct" "$RESET"
}

# "▰▰▰▱▱▱▱▱ 34%" — filled cells colored by threshold, empty cells dim.
bar_pct() {
  local pct filled i bar=""
  pct=$(printf "%.0f" "$1" 2>/dev/null) || return
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( (pct * BAR_WIDTH + 50) / 100 ))
  for ((i = 0; i < BAR_WIDTH; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+="$BAR_FULL"; else bar+="$BAR_EMPTY"; fi
  done
  printf "%s%s%s %s%%" "$(pct_color "$pct")" "$bar" "$RESET" "$pct"
}

# Epoch → "5:00 PM", or "Fri 3:00 PM" when the reset isn't today.
fmt_time() {
  local epoch="$1" time_str reset_day
  [ -z "$epoch" ] && return
  time_str=$(date -r "$epoch" "+%-I:%M %p" 2>/dev/null || date -d "@$epoch" "+%-I:%M %p" 2>/dev/null)
  [ -z "$time_str" ] && return
  reset_day=$(date -r "$epoch" "+%Y-%m-%d" 2>/dev/null || date -d "@$epoch" "+%Y-%m-%d" 2>/dev/null)
  if [ "$reset_day" != "$(date "+%Y-%m-%d")" ]; then
    printf "%s %s" "$(date -r "$epoch" "+%a" 2>/dev/null || date -d "@$epoch" "+%a" 2>/dev/null)" "$time_str"
  else
    printf "%s" "$time_str"
  fi
}

# ISO-8601 (2026-07-11T12:59:59.87+00:00) → epoch seconds.
iso_to_epoch() {
  local iso="$1" trimmed
  [ -z "$iso" ] && return
  trimmed="${iso%%.*}"; trimmed="${trimmed%%+*}"
  date -u -j -f "%Y-%m-%dT%H:%M:%S" "$trimmed" +%s 2>/dev/null \
    || date -d "$iso" +%s 2>/dev/null
}

# --- Context window -----------------------------------------------------------
if [ -z "$ctx_pct" ]; then
  # Fallback: estimate from the transcript's most recent usage entry.
  [ -z "$window_size" ] && window_size=200000
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    tokens=$(tail -n 300 "$transcript" 2>/dev/null | jq -rs '
      [.[] | select(.message.usage != null)] | last | .message.usage
      | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
    ' 2>/dev/null)
    if [ -n "$tokens" ] && [ "$tokens" != "null" ]; then
      ctx_pct=$(awk -v t="$tokens" -v w="$window_size" 'BEGIN { if (w>0) printf "%.0f", (t/w)*100 }')
    fi
  fi
fi

ctx_str=""
[ -n "$ctx_pct" ] && ctx_str="$ICON_CTX $(bar_pct "$ctx_pct")"

# --- 5-hour session limit -----------------------------------------------------
five_str=""
if [ -n "$five_pct" ]; then
  five_str="$ICON_SESSION $(color_pct "$five_pct")"
  rt=$(fmt_time "$five_reset")
  [ -n "$rt" ] && five_str="$five_str ${DIM}→ $rt${RESET}"
fi

# --- Model-scoped weekly limit (usage API, cached) ----------------------------
usage_cache="$HOME/.claude/statusline-usage-cache.json"
cache_fresh=false
if [ -f "$usage_cache" ]; then
  cache_mtime=$(stat -f %m "$usage_cache" 2>/dev/null || stat -c %Y "$usage_cache" 2>/dev/null)
  [ -n "$cache_mtime" ] && [ $(( $(date +%s) - cache_mtime )) -lt 60 ] && cache_fresh=true
fi
if [ "$cache_fresh" != true ]; then
  oauth_token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
    | jq -r '.claudeAiOauth.accessToken // empty')
  if [ -z "$oauth_token" ] && [ -f "$HOME/.claude/.credentials.json" ]; then
    oauth_token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  fi
  if [ -n "$oauth_token" ]; then
    usage_resp=$(curl -s --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
      -H "Authorization: Bearer $oauth_token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "Content-Type: application/json" 2>/dev/null)
    # Only replace the cache with a response that actually has limits; write
    # atomically so a concurrent render never reads a half-written file.
    if [ -n "$usage_resp" ] && printf "%s" "$usage_resp" | jq -e '.limits' >/dev/null 2>&1; then
      ( umask 077; printf "%s" "$usage_resp" > "$usage_cache.tmp.$$" ) && mv -f "$usage_cache.tmp.$$" "$usage_cache"
    fi
  fi
fi

scoped_pct="" scoped_label="" scoped_iso=""
if [ -f "$usage_cache" ]; then
  IFS="$US" read -r scoped_pct scoped_label scoped_iso < <(
    jq -r '[.limits[]? | select(.kind=="weekly_scoped")][0]
      | [ .percent, (.scope.model.display_name // "Model"), .resets_at ]
      | map(if . == null then "" else tostring end) | join("\u001f")' "$usage_cache" 2>/dev/null
  )
fi

# --- 7-day weekly limits ------------------------------------------------------
week_rt=$(fmt_time "$week_reset")
if [ -z "$week_rt" ] && [ -n "$scoped_iso" ]; then
  week_rt=$(fmt_time "$(iso_to_epoch "$scoped_iso")")
fi

week_str=""
if [ -n "$week_pct" ] && [ -n "$scoped_pct" ]; then
  week_str="${DIM}All${RESET} $(color_pct "$week_pct") ${DIM}·${RESET} ${DIM}${scoped_label}${RESET} $(color_pct "$scoped_pct")"
elif [ -n "$week_pct" ]; then
  week_str="$(color_pct "$week_pct")"
elif [ -n "$scoped_pct" ]; then
  week_str="${DIM}${scoped_label}${RESET} $(color_pct "$scoped_pct")"
fi
if [ -n "$week_str" ]; then
  week_str="$ICON_WEEK $week_str"
  [ -n "$week_rt" ] && week_str="$week_str ${DIM}→ $week_rt${RESET}"
fi

# --- Workspace: directory + git branch ---------------------------------------
dir_str="" git_str=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  if [ "$cwd" = "$HOME" ]; then dir_name="~"; else dir_name="${cwd##*/}"; fi
  dir_str="$ICON_DIR $dir_name"
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=""
    [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ] && dirty="*"
    git_str="$ICON_GIT $branch$dirty"
  fi
fi

# --- Assemble -----------------------------------------------------------------
parts=()
[ -n "$ctx_str" ] && parts+=("$ctx_str")
[ -n "$five_str" ] && parts+=("$five_str")
[ -n "$week_str" ] && parts+=("$week_str")
[ -n "$dir_str" ] && parts+=("$dir_str")
[ -n "$git_str" ] && parts+=("$git_str")
[ -n "$model_name" ] && parts+=("${BOLD}${model_name}${RESET}")

out=""
for p in "${parts[@]}"; do
  [ -z "$out" ] && out="$p" || out="$out$SEP$p"
done

[ -z "$out" ] && out="Usage info unavailable — type /usage"
printf "%s" "$out"
