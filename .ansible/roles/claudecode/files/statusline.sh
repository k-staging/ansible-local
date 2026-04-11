#!/bin/bash
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

PCT=${PCT:-0}; COST=${COST:-0}; DURATION_MS=${DURATION_MS:-0}
[ "$PCT" -gt 100 ] && PCT=100

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

COST_FMT=$(printf '$%.2f' "$COST")
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

printf '%b\n' "${CYAN}[${MODEL}]${RESET} ${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${YELLOW}${COST_FMT}${RESET} | ${MINS}m ${SECS}s${LIMITS}"
