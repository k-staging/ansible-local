#!/bin/bash
# SessionStart hook: 前回の実行から一定日数たっていたら、claude -p をバックグラウンドで起動し、
# 直近のセッション履歴をもとに CLAUDE.md・サブエージェント・スキルの見直しレポートを作る。
# 未通知のレポートがあれば、その場所を stdout に出してセッションのコンテキストに渡す。
set -euo pipefail

# この hook から起動した claude -p の中では何もしない（再帰起動の防止）
[ -n "${CLAUDE_CONFIG_REVIEW_RUNNING:-}" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

REPORT_DIR="$HOME/.claude/config-reviews"
PROMPT_FILE="$HOME/.claude/hooks/config-review-prompt.md"
STAMP_FILE="$REPORT_DIR/.last-run"
NOTIFIED_FILE="$REPORT_DIR/.notified"
FAILED_FILE="$REPORT_DIR/.failed"
ERROR_LOG="$REPORT_DIR/last-error.log"
LOCK_DIR="$REPORT_DIR/.lock"
INTERVAL_DAYS="${CONFIG_REVIEW_INTERVAL_DAYS:-7}"
BUDGET_USD="${CONFIG_REVIEW_BUDGET_USD:-5}"
[[ "$INTERVAL_DAYS" =~ ^[1-9][0-9]*$ ]] || INTERVAL_DAYS=7

[ -f "$PROMPT_FILE" ] || exit 0
mkdir -p "$REPORT_DIR"

# 未通知のレポートがあれば知らせる（作成中のものは *.md.tmp なので対象外）
latest=$(find "$REPORT_DIR" -maxdepth 1 -name '*.md' | sort | tail -n 1)
notified=$(cat "$NOTIFIED_FILE" 2>/dev/null || true)
if [ -n "$latest" ] && [ "$latest" != "$notified" ]; then
    echo "Claude Code 設定の見直しレポートが作成されています: $latest"
    echo "このレポートを読んで要約し、改善案をユーザーに提示すること。"
    echo "$latest" > "$NOTIFIED_FILE"
fi
if [ -f "$FAILED_FILE" ]; then
    echo "前回の Claude Code 設定の見直しは失敗した。ユーザーに伝えること。エラーログ: $ERROR_LOG"
    rm -f "$FAILED_FILE"
fi

now=$(date +%s)
if [ -f "$STAMP_FILE" ]; then
    last=$(cat "$STAMP_FILE")
    if [[ "$last" =~ ^[0-9]+$ ]] && [ $((now - last)) -lt $((INTERVAL_DAYS * 86400)) ]; then
        exit 0
    fi
fi

# 同時に開いた別セッションと二重に起動しない。異常終了で残ったロック（1 日以上前）は消し、次に実行期限が来たセッションで再実行する
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1440)" ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
    exit 0
fi
# 失敗しても毎セッション起動し直さないよう、起動した時点で記録する
echo "$now" > "$STAMP_FILE"

report="$REPORT_DIR/$(date +%Y-%m-%d).md"
(
    trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
    trap '' HUP
    cd "$HOME/.claude"
    # 読み取り専用の組み込みツールだけを渡し、MCP は読み込ませない。レポートは stdout から書き出し、完了してから *.md にする
    if { cat "$PROMPT_FILE"; printf '\n対象期間: 直近 %s 日間\n' "$INTERVAL_DAYS"; } | CLAUDE_CONFIG_REVIEW_RUNNING=1 claude -p \
        --tools "Read,Grep,Glob" \
        --strict-mcp-config \
        --no-session-persistence \
        --max-budget-usd "$BUDGET_USD" \
        > "$report.tmp" 2> "$ERROR_LOG" && [ -s "$report.tmp" ]; then
        if mv "$report.tmp" "$report"; then
            rm -f "$ERROR_LOG"
        else
            echo "failed to move $report.tmp to $report" >> "$ERROR_LOG"
            touch "$FAILED_FILE"
        fi
    else
        echo "config review failed (status $?)" >> "$ERROR_LOG"
        [ -s "$report.tmp" ] || echo "claude -p produced no output" >> "$ERROR_LOG"
        rm -f "$report.tmp"
        touch "$FAILED_FILE"
    fi
) < /dev/null > /dev/null 2>&1 &
disown
