#!/bin/bash
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CURRENT_VERSION=$(echo "$input" | jq -r '.version // empty' | sed 's/^v//')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

PCT=${PCT:-0}; DURATION_MS=${DURATION_MS:-0}
[ "$PCT" -gt 100 ] && PCT=100

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; MAGENTA='\033[35m'; RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

fmt_remaining() {
  local resets_at=$1 now remaining
  [ -z "$resets_at" ] && return
  now=$(date +%s)
  remaining=$((resets_at - now))
  [ "$remaining" -le 0 ] && echo "0m" && return
  local days=$((remaining / 86400))
  local hours=$(( (remaining % 86400) / 3600 ))
  local mins=$(( (remaining % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then echo "${days}d${hours}h"
  elif [ "$hours" -gt 0 ]; then echo "${hours}h${mins}m"
  else echo "${mins}m"
  fi
}

LIMITS=""
if [ -n "$FIVE_H" ]; then
  FIVE_H_REM=$(fmt_remaining "$FIVE_H_RESET")
  LIMITS=" | 5h: $(printf '%.0f' "$FIVE_H")%"
  [ -n "$FIVE_H_REM" ] && LIMITS="${LIMITS}(${FIVE_H_REM})"
fi
if [ -n "$WEEK" ]; then
  WEEK_REM=$(fmt_remaining "$WEEK_RESET")
  LIMITS="${LIMITS} 7d: $(printf '%.0f' "$WEEK")%"
  [ -n "$WEEK_REM" ] && LIMITS="${LIMITS}(${WEEK_REM})"
fi

CWD=$(echo "$input" | jq -r '.workspace.current_dir // empty')
CWD_SUFFIX=""
[ -n "$CWD" ] && CWD_SUFFIX=" ${CYAN}$(basename "$CWD")${RESET}"

PR_INFO=""
if [ -n "$CWD" ] && command -v gh >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
  REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  case "$BRANCH" in
    ""|HEAD|main|master|develop) ;;
    *)
      if [ -n "$REPO_ROOT" ]; then
        CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-pr-cache"
        mkdir -p "$CACHE_DIR" 2>/dev/null
        CACHE_KEY=$(printf '%s' "${REPO_ROOT}:${BRANCH}" | shasum 2>/dev/null | cut -c1-16)
        if [ -n "$CACHE_KEY" ]; then
          CACHE_FILE="${CACHE_DIR}/${CACHE_KEY}"
          CACHE_MTIME=0
          if [ -f "$CACHE_FILE" ]; then
            PR_INFO=$(cat "$CACHE_FILE")
            CACHE_MTIME=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
          fi
          CACHE_AGE=$(( $(date +%s) - CACHE_MTIME ))
          if [ "$CACHE_AGE" -gt 300 ] && mkdir "${CACHE_FILE}.lock" 2>/dev/null; then
            (
              trap 'rmdir "${CACHE_FILE}.lock" 2>/dev/null' EXIT
              cd "$REPO_ROOT" || exit
              pr_data=$(gh pr view "$BRANCH" --json number,title --jq '"#\(.number) \(.title)"' 2>/dev/null | tr -d '\n')
              tmp_file=$(mktemp "${CACHE_DIR}/.pr-XXXXXX" 2>/dev/null) || exit
              printf '%s' "$pr_data" > "$tmp_file" && mv "$tmp_file" "$CACHE_FILE"
              find "$CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null
            ) >/dev/null 2>&1 &
          fi
        fi
      fi
      ;;
  esac
fi
PR_SUFFIX=""
[ -n "$PR_INFO" ] && PR_SUFFIX=" | ${MAGENTA}${PR_INFO}${RESET}"

LATEST_VERSION=""
if [ -n "$CURRENT_VERSION" ] && command -v curl >/dev/null 2>&1; then
  UPDATE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-update-cache"
  mkdir -p "$UPDATE_CACHE_DIR" 2>/dev/null
  UPDATE_CACHE_FILE="${UPDATE_CACHE_DIR}/latest-version"
  UPDATE_CACHE_MTIME=0
  if [ -f "$UPDATE_CACHE_FILE" ]; then
    LATEST_VERSION=$(cat "$UPDATE_CACHE_FILE")
    UPDATE_CACHE_MTIME=$(stat -f %m "$UPDATE_CACHE_FILE" 2>/dev/null || stat -c %Y "$UPDATE_CACHE_FILE" 2>/dev/null || echo 0)
  fi
  UPDATE_CACHE_AGE=$(( $(date +%s) - UPDATE_CACHE_MTIME ))
  if [ "$UPDATE_CACHE_AGE" -gt 3600 ] && mkdir "${UPDATE_CACHE_FILE}.lock" 2>/dev/null; then
    (
      trap 'rmdir "${UPDATE_CACHE_FILE}.lock" 2>/dev/null' EXIT
      latest=$(curl -sf --max-time 3 "https://downloads.claude.ai/claude-code-releases/latest" 2>/dev/null | tr -d '[:space:]' | sed 's/^v//')
      if [ -n "$latest" ]; then
        tmp_file=$(mktemp "${UPDATE_CACHE_DIR}/.latest-XXXXXX" 2>/dev/null) || exit
        printf '%s' "$latest" > "$tmp_file" && mv "$tmp_file" "$UPDATE_CACHE_FILE"
      fi
    ) >/dev/null 2>&1 &
  fi
fi
UPDATE_SUFFIX=""
[ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$CURRENT_VERSION" ] && UPDATE_SUFFIX=" | ${YELLOW}⬆ v${LATEST_VERSION}${RESET}"

printf '%b\n' "${CYAN}[${MODEL}]${RESET}${CWD_SUFFIX} ${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${MINS}m ${SECS}s${LIMITS}${PR_SUFFIX}${UPDATE_SUFFIX}"
