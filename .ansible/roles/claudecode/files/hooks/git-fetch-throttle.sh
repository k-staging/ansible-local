#!/bin/bash
set -euo pipefail

STATE_FILE="$HOME/.claude/.git-fetch-last-run"
INTERVAL=3600 # 1 hour
SEARCH_DIR="${GIT_FETCH_DIRS:-$HOME/src}"

if [ -f "$STATE_FILE" ]; then
    last=$(cat "$STATE_FILE")
    now=$(date +%s)
    if [[ "$last" =~ ^[0-9]+$ ]] && [ $((now - last)) -lt $INTERVAL ]; then
        exit 0
    fi
fi

date +%s > "$STATE_FILE"

find "$SEARCH_DIR" -maxdepth 2 -name ".git" -type d 2>/dev/null | while IFS= read -r gitdir; do
    repo="${gitdir%/.git}"
    git -C "$repo" fetch --all --prune --quiet 2>/dev/null &
done
wait || true # ignore fetch failures (network unavailable etc.)
