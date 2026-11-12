#!/bin/bash
# Claude Code のクラウドセッションで、main などへの直接コミット・push を防ぐ
#
# 使い方（.claude/settings.json のフックから呼ぶ）:
#   bash scripts/cloud-git-guard.sh setup  # SessionStart: ローカルと同じ git フックを入れる
#   bash scripts/cloud-git-guard.sh check  # PreToolUse(Bash): git フックを迂回するコマンドを止める
#
# ローカルのセッション（CLAUDE_CODE_REMOTE が true でない）では何もしない
# （ローカルの git フックは common ロールが入れる）
set -euo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
    exit 0
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_SRC="${REPO_DIR}/ansible/roles/common/files/git-hooks"
HOOKS_DIR="${HOME}/.config/git/hooks"

setup() {
    mkdir -p "$HOOKS_DIR"
    # リポジトリ内のフックは実行権限なしでコミットされているため、実行権限を付けてコピーする
    install -m 0755 "${HOOKS_SRC}/pre-commit" "${HOOKS_SRC}/pre-push" "$HOOKS_DIR/"
    git config --global core.hooksPath "$HOOKS_DIR"
}

check() {
    local command
    command="$(jq -r '.tool_input.command // empty')"

    # 同じ git コマンド内（; & | 改行 で区切られるまで）だけを見る
    local sep='[^;&|'$'\n'']'
    # git は曖昧でない長いオプションの省略を受け付けるため、--no-veri まで一致すれば止める
    local no_verify_re='git[[:space:]]'"$sep"'*--no-veri'
    local commit_n_re='git[[:space:]]('"$sep"'*[[:space:]])?commit[[:space:]]('"$sep"'*[[:space:]])?-[a-zA-Z]*n'

    local reason=""
    if [[ "$command" =~ $no_verify_re ]]; then
        reason="--no-verify で git フックを迂回する操作"
    elif [[ "$command" =~ $commit_n_re ]]; then
        reason="git commit -n で git フックを迂回する操作"
    elif [[ "${command,,}" == *core.hookspath* ]]; then
        reason="core.hooksPath の変更"
    fi

    if [[ -n "$reason" ]]; then
        echo "ERROR: クラウドセッションでは${reason}は禁止されています。main への直接コミット・push はせず、作業ブランチから PR を作成してください。" >&2
        exit 2
    fi
}

case "${1:-}" in
    setup) setup ;;
    check) check ;;
    *)
        echo "ERROR: 引数には setup か check を指定してください" >&2
        exit 1
        ;;
esac
