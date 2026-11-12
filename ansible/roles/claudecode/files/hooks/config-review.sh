#!/bin/bash
# SessionStart hook: 前回の実行から一定日数たっていたら、claude -p をバックグラウンドで起動し、
# 直近のセッション履歴をもとに、設定を管理するリポジトリの CLAUDE.md・ルール・サブエージェント・スキルを修正して PR を作る。
# merge は人が判断する。結果（PR の URL・改善案）は次のセッション開始時に stdout でコンテキストに渡す。
set -euo pipefail

# この hook から起動した claude -p の中では何もしない（再帰起動の防止）
[ -n "${CLAUDE_CONFIG_REVIEW_RUNNING:-}" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

REPORT_DIR="$HOME/.claude/config-reviews"
PROMPT_FILE="$HOME/.claude/hooks/config-review-prompt.md"
SAFETY_PROMPT_FILE="$HOME/.claude/hooks/config-review-safety-prompt.md"
DENYLIST_FILE="$HOME/.config/public-safety-check/denylist"
STAMP_FILE="$REPORT_DIR/.last-run"
NOTIFIED_FILE="$REPORT_DIR/.notified"
FAILED_FILE="$REPORT_DIR/.failed"
ERROR_LOG="$REPORT_DIR/last-error.log"
LOCK_DIR="$REPORT_DIR/.lock"
INTERVAL_DAYS="${CONFIG_REVIEW_INTERVAL_DAYS:-7}"
BUDGET_USD="${CONFIG_REVIEW_BUDGET_USD:-5}"
# 設定を管理するリポジトリ（Ansible が playbook を実行したリポジトリの本体の checkout を渡す）
CONFIG_REPO="${CONFIG_REVIEW_REPO:-}"
MODEL="${CONFIG_REVIEW_MODEL:-}"
# 見直しで変更してよい範囲（既存ファイルの修正だけを許可する。フック・スクリプト・プロンプトは対象外）
ALLOWED_PATHS=(
    "ansible/roles/claudecode/files/CLAUDE.md"
    "ansible/roles/claudecode/files/claude-rules"
    "ansible/roles/claudecode/files/claude-agents"
    "ansible/roles/claudecode/files/claude-skills"
)
[[ "$INTERVAL_DAYS" =~ ^[1-9][0-9]*$ ]] || INTERVAL_DAYS=7

# 設定リポジトリ（とその worktree）で起動したセッションのときだけ動く。
# どのリポジトリのセッションでも毎回呼ばれるため、CONFIG_REVIEW_REPO が未設定・不正な場合もログを残さずに終える
[ -n "$CONFIG_REPO" ] || exit 0
config_git_dir=$(git -C "$CONFIG_REPO" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
cwd_git_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
[ "$cwd_git_dir" = "$config_git_dir" ] || exit 0

[ -f "$PROMPT_FILE" ] || exit 0
[ -f "$SAFETY_PROMPT_FILE" ] || exit 0
mkdir -p "$REPORT_DIR"

# 未通知の結果があれば知らせる（作成中のものは *.md.tmp なので対象外）
latest=$(find "$REPORT_DIR" -maxdepth 1 -name '*.md' | sort | tail -n 1)
notified=$(cat "$NOTIFIED_FILE" 2>/dev/null || true)
if [ -n "$latest" ] && [ "$latest" != "$notified" ]; then
    echo "Claude Code 設定の定期見直しの結果があります: $latest"
    echo "このファイルを読み、作成した PR の URL と変更内容、反映しなかった改善案を要約してユーザーに伝えること。"
    echo "$latest" > "$NOTIFIED_FILE"
fi
if [ -f "$FAILED_FILE" ]; then
    echo "前回の Claude Code 設定の定期見直しは失敗した。ユーザーに伝えること。エラーログ: $ERROR_LOG"
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

today=$(date +%Y-%m-%d)
report="$REPORT_DIR/$today.md"
branch="chore/config-review-$(date +%Y%m%d)"

log() { echo "$*" >> "$ERROR_LOG"; }

is_allowed_path() {
    local p
    for p in "${ALLOWED_PATHS[@]}"; do
        if [ "$1" = "$p" ] || [[ "$1" == "$p/"* ]]; then
            return 0
        fi
    done
    return 1
}

# 追加行・PR ディスクリプションに個人情報が含まれていないかを機械的に検査する。検出した値そのものはログに書かない
safety_grep() {
    local file="$1" ng=0 name
    if grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$file" \
        | grep -vE '^(git@github\.com|noreply@anthropic\.com|.*@users\.noreply\.github\.com)$' | grep -q .; then
        log "safety: メールアドレスを検出"; ng=1
    fi
    if grep -oE '/(Users|home)/[A-Za-z0-9._-]+' "$file" | grep -vE '^/home/linuxbrew$' | grep -q .; then
        log "safety: 個人の絶対パスを検出"; ng=1
    fi
    if [ -n "${USER:-}" ] && grep -qiwF -- "$USER" "$file"; then
        log "safety: 実行環境のユーザー名を検出"; ng=1
    fi
    name=$(git config user.name 2>/dev/null || true)
    if [ -n "$name" ] && grep -qiF -- "$name" "$file"; then
        log "safety: git のユーザー名を検出"; ng=1
    fi
    # 空行があると全行に一致するため、空行を除いてから使う
    if [ -s "$DENYLIST_FILE" ] && grep -v '^[[:space:]]*$' "$DENYLIST_FILE" | grep -qiF -f - "$file"; then
        log "safety: 単語リストの語を検出"; ng=1
    fi
    return "$ng"
}

# コミット前の worktree とブランチを消す。途中で止まったときも EXIT trap から呼ばれる
CLEANUP_REPO=""
CLEANUP_WT=""
cleanup_worktree() {
    [ -n "$CLEANUP_WT" ] || return 0
    git -C "$CLEANUP_REPO" worktree remove --force "$CLEANUP_WT" 2>> "$ERROR_LOG" || rm -rf "$CLEANUP_WT"
    git -C "$CLEANUP_REPO" worktree prune 2>/dev/null || true
    git -C "$CLEANUP_REPO" branch -D "$branch" >/dev/null 2>&1 || true
    rm -f "$CLEANUP_WT.diff" "$CLEANUP_WT.check"
    CLEANUP_WT=""
}

review() {
    local repo base wt body diff_file check_file safety_out status path url

    # worktree から playbook を実行していても、本体の checkout を基準にする
    repo=$(dirname "$config_git_dir")
    command -v gh >/dev/null 2>&1 || { log "gh コマンドがない"; return 1; }

    # if の条件から呼ばれる関数の中では set -e が効かないため、失敗を個別に判定する
    git -C "$repo" fetch --quiet origin 2>> "$ERROR_LOG" || { log "git fetch に失敗した"; return 1; }
    base=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
    base="${base#origin/}"

    # 強制終了などで後始末されずに残ったブランチのうち、コミットのないものを消す
    # （push・PR 作成に失敗したコミット済みのブランチは、origin の祖先にならないので残る）
    git -C "$repo" worktree prune
    git -C "$repo" for-each-ref --format='%(refname:short)' 'refs/heads/chore/config-review-*' | while IFS= read -r b; do
        if git -C "$repo" merge-base --is-ancestor "$b" "origin/$base"; then
            git -C "$repo" branch -D "$b" >/dev/null 2>&1 || true
        fi
    done
    wt=$(mktemp -d "${TMPDIR:-/tmp}/claude-config-review.XXXXXX") || { log "一時ディレクトリを作れない"; return 1; }
    if ! git -C "$repo" worktree add --quiet --no-track -b "$branch" "$wt" "origin/$base" 2>> "$ERROR_LOG" || ! cd "$wt"; then
        log "worktree を作れない: $wt"
        rmdir "$wt" 2>/dev/null || true
        return 1
    fi
    CLEANUP_REPO="$repo"
    CLEANUP_WT="$wt"

    body="$report.tmp"
    # ユーザー設定（広い Edit 許可や acceptEdits）は読ませず、必要な権限だけを渡す。
    # 編集は許可した範囲の既存ファイルだけ（Write は渡さず、新規ファイルは作らせない）。
    # 読み取りは worktree（カレントディレクトリ）のほか、セッション履歴と過去の見直し結果だけに絞る（認証情報などを読ませない）
    local edit_rules=() p
    for p in "${ALLOWED_PATHS[@]}"; do
        edit_rules+=("Edit(${p})" "Edit(${p}/**)")
    done
    local common_opts=(--setting-sources project --permission-mode default --strict-mcp-config --no-session-persistence)
    [ -n "$MODEL" ] && common_opts+=(--model "$MODEL")
    if ! { cat "$PROMPT_FILE"; printf '\n対象期間: 直近 %s 日間\n' "$INTERVAL_DAYS"; } | CLAUDE_CONFIG_REVIEW_RUNNING=1 claude -p \
        "${common_opts[@]}" \
        --tools "Read,Grep,Glob,Edit" \
        --allowedTools "Read(~/.claude/projects/**)" "Read(~/.claude/config-reviews/**)" "${edit_rules[@]}" \
        --max-budget-usd "$BUDGET_USD" \
        > "$body" 2>> "$ERROR_LOG" || [ ! -s "$body" ]; then
        log "claude -p による見直しが失敗した"
        return 1
    fi

    # 変更なし: 改善案だけをレポートとして残す
    if [ -z "$(git status --porcelain)" ]; then
        cleanup_worktree
        mv "$body" "$report"
        return 0
    fi

    # 許可した範囲の既存ファイルの修正だけかを確かめる（Edit の許可とは別に、結果でも確かめる）
    while IFS= read -r status; do
        path="${status:3}"
        if [ "${status:0:2}" != " M" ] || ! is_allowed_path "$path"; then
            log "許可していない変更があるため PR を作らない: $status"
            return 1
        fi
    done < <(git status --porcelain)

    diff_file="$wt.diff"
    check_file="$wt.check"
    if ! git diff -U0 > "$diff_file" 2>> "$ERROR_LOG" || [ ! -s "$diff_file" ]; then
        log "差分を取得できない"
        return 1
    fi
    { grep '^+' "$diff_file" || true; cat "$body"; } > "$check_file"
    if ! safety_grep "$check_file"; then
        log "個人情報の検査で NG が出たため PR を作らない"
        return 1
    fi
    # 文脈で判断する内容の確認は、ツールを渡さない claude -p に任せる。1 行目が OK のときだけ進む
    # 差分にはコードフェンスが含まれうるため、中身に出てこないタグで区切る
    safety_out=$({ cat "$SAFETY_PROMPT_FILE"; printf '\n<diff>\n'; cat "$diff_file"; printf '\n</diff>\n\n<pr_description>\n'; cat "$body"; printf '\n</pr_description>\n'; } \
        | CLAUDE_CONFIG_REVIEW_RUNNING=1 claude -p "${common_opts[@]}" --tools "" --max-budget-usd 1 2>> "$ERROR_LOG" || true)
    if [ "$(printf '%s\n' "$safety_out" | head -n 1 | tr -d '[:space:]')" != "OK" ]; then
        log "内容の確認で NG が出たため PR を作らない:"
        log "$safety_out"
        return 1
    fi
    rm -f "$diff_file" "$check_file"

    # 変更が許可した範囲の既存ファイルだけであることは上で確かめている（存在しないパスを pathspec に渡すと失敗するため、範囲は指定しない）
    if ! git add -u 2>> "$ERROR_LOG" \
        || ! git commit --quiet -m "Claude Code 設定の定期見直しを反映する（$today）" 2>> "$ERROR_LOG"; then
        log "コミットに失敗した"
        return 1
    fi
    # コミット済みの変更を失わないよう、ここから先の失敗では worktree とブランチを残す
    CLEANUP_WT=""
    if ! git push --quiet origin "HEAD:refs/heads/$branch" 2>> "$ERROR_LOG" \
        || ! url=$(gh pr create --base "$base" --head "$branch" --title "Claude Code 設定の定期見直し（$today）" --body-file "$body" 2>> "$ERROR_LOG"); then
        log "push または PR 作成に失敗した。ブランチ: $branch、worktree: $wt"
        { printf 'PR を作成できなかった。ブランチ: %s、worktree: %s\n\n' "$branch" "$wt"; cat "$body"; } > "$report"
        rm -f "$body"
        return 1
    fi
    { printf 'PR: %s\n\n' "$url"; cat "$body"; } > "$report"
    rm -f "$body"
    # push 済みなのでローカルの worktree とブランチは消す
    CLEANUP_WT="$wt"
    cleanup_worktree
}

(
    trap 'cleanup_worktree; rmdir "$LOCK_DIR" 2>/dev/null' EXIT
    trap 'exit 143' TERM INT
    trap '' HUP
    : > "$ERROR_LOG"
    if review; then
        rm -f "$ERROR_LOG"
    else
        rm -f "$report.tmp"
        touch "$FAILED_FILE"
    fi
) < /dev/null > /dev/null 2>&1 &
disown
