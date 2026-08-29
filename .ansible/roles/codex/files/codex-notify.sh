#!/bin/bash
set -euo pipefail

if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Codex CLI" -message "タスクが完了しました" -sound Ping || true
fi

# ChatGPT デスクトップアプリ (Computer Use) が使う通知フックが存在する場合は併せて呼び出す
CHATGPT_NOTIFY_BIN="$HOME/.codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient"
if [ -x "$CHATGPT_NOTIFY_BIN" ]; then
    "$CHATGPT_NOTIFY_BIN" "turn-ended" "$@" || true
fi
