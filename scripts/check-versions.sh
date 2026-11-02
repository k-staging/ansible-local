#!/bin/bash
# ansible/group_vars/all/versions.yml のバージョンを最新版と比べ、古いものを出力する（ファイルは書き換えない）
#
# 使い方:
#   bash scripts/check-versions.sh                  # 最新版を調べて結果を表示し、キャッシュに保存する
#   bash scripts/check-versions.sh --session-start  # キャッシュを表示する。キャッシュが古ければ裏で再チェックする
#
# 「固定」とコメントしてある項目（同じ行か、直前に続くコメント行に書いてあるもの）は対象外
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${REPO_DIR}/ansible/group_vars/all/versions.yml"
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/ansible-local"
CACHE_FILE="${CACHE_DIR}/outdated.txt"
LOCK_DIR="${CACHE_DIR}/check-versions.lock"
# キャッシュの有効期間（日）
CACHE_MAX_AGE_DAYS=7

export GIT_TERMINAL_PROMPT=0

outdated=()
failed=()
# 最新版を取得できた項目の数（全項目が失敗したときにキャッシュを置き換えないために使う）
succeeded=0
# 通信などで最新版を取得できなかった項目の数（調べ先が未定義・解釈できない行は含めない）
fetch_failed=0

# 先頭の v を外して比べる（タグ名とファイル上の書き方の違いを吸収する）
strip_v() {
    echo "${1#v}"
}

github_latest_release() {
    gh api "repos/$1/releases/latest" --jq .tag_name 2>/dev/null
}

# Go パッケージのパスから、@latest を解決できるモジュールパスを探す（cmd/... などのサブパスを外していく）
# 親のモジュールにさかのぼるのは「そのパスのモジュールはない」と返ったときだけにする
# （通信エラーなどでさかのぼると、親のモジュールのバージョンと比べてしまうため）
go_latest() {
    local path="$1" out
    while [ -n "${path}" ]; do
        if out=$(cd "${TMPDIR:-/tmp}" && go list -m -f '{{.Version}}' "${path}@latest" 2>&1); then
            echo "${out}"
            return 0
        fi
        case "${out}" in
            *"no matching versions"* | *"404 Not Found"* | *"410 Gone"*) ;;
            *) return 1 ;;
        esac
        case "${path}" in
            */*) path="${path%/*}" ;;
            *) path="" ;;
        esac
    done
    return 1
}

# 比較して古ければ outdated に追加する。最新版が取れなければ failed に追加する
compare() {
    local name="$1" current="$2" latest="$3"
    if [ -z "${latest}" ]; then
        failed+=("${name}")
        fetch_failed=$((fetch_failed + 1))
        return
    fi
    succeeded=$((succeeded + 1))
    if [ "$(strip_v "${current}")" != "$(strip_v "${latest}")" ]; then
        # 表示はファイル上の書き方（v の有無）に合わせる
        [[ "${current}" == v* ]] || latest="$(strip_v "${latest}")"
        outdated+=("${name}: ${current} -> ${latest}")
    fi
}

check_scalar() {
    local key="$1" current="$2" latest=""
    case "${key}" in
        uv_version) latest=$(github_latest_release astral-sh/uv) || true ;;
        python3_version) latest=$(mise latest python 2>/dev/null) || true ;;
        ruby_version) latest=$(mise latest ruby 2>/dev/null) || true ;;
        node_version) latest=$(mise latest node 2>/dev/null) || true ;;
        go_version) latest=$(mise latest go 2>/dev/null) || true ;;
        cloud_sql_proxy_version) latest=$(github_latest_release GoogleCloudPlatform/cloud-sql-proxy) || true ;;
        tmux_version) latest=$(github_latest_release tmux/tmux) || true ;;
        neovim_version) latest=$(github_latest_release neovim/neovim) || true ;;
        oxker_version) latest=$(github_latest_release mrjackwills/oxker) || true ;;
        lazygit_version) latest=$(github_latest_release jesseduffield/lazygit) || true ;;
        tree_sitter_cli_version) latest=$(github_latest_release tree-sitter/tree-sitter) || true ;;
        *)
            failed+=("${key}（調べ先が scripts/check-versions.sh に未定義）")
            return
            ;;
    esac
    compare "${key}" "${current}" "${latest}"
}

check_list_item() {
    local list="$1" item="$2" name current latest=""
    case "${list}" in
        pip_packages)
            name="${item%%==*}"
            current="${item#*==}"
            latest=$(curl -fsSL --max-time 20 "https://pypi.org/pypi/${name}/json" 2>/dev/null | jq -r '.info.version // empty') || true
            ;;
        npm_packages)
            # スコープ付きパッケージ（@scope/name@1.0.0）も扱えるよう、最後の @ で分ける
            name="${item%@*}"
            current="${item##*@}"
            # 既定のままだと通信できないときに数分リトライし続けるため、回数と待ち時間を絞る
            latest=$(npm view --fetch-retries=1 --fetch-timeout=20000 "${name}" version 2>/dev/null) || true
            ;;
        go_packages)
            name="${item%@*}"
            current="${item##*@}"
            latest=$(go_latest "${name}") || true
            ;;
        *)
            failed+=("${list}: ${item}（調べ先が scripts/check-versions.sh に未定義）")
            return
            ;;
    esac
    compare "${list}: ${name}" "${current}" "${latest}"
}

check_neovim_plugin() {
    local name="$1" current="$2" latest=""
    if [[ "${current}" =~ ^[0-9a-f]{40}$ ]]; then
        # SHA 指定は既定ブランチの先頭と比べる
        # 転送が 20 秒止まったら打ち切る
        latest=$(git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=20 ls-remote "https://github.com/${name}.git" HEAD 2>/dev/null | cut -f1) || true
        if [ -z "${latest}" ]; then
            failed+=("neovim_plugins: ${name}")
            fetch_failed=$((fetch_failed + 1))
            return
        fi
        succeeded=$((succeeded + 1))
        if [ "${current}" != "${latest}" ]; then
            outdated+=("neovim_plugins: ${name}: ${current:0:7} -> ${latest:0:7}（既定ブランチの先頭）")
        fi
    else
        # タグ指定は最新リリースと比べる
        latest=$(github_latest_release "${name}") || true
        compare "neovim_plugins: ${name}" "${current}" "${latest}"
    fi
}

run_check() {
    local line section="" comment_pinned=false pinned plugin_name="" plugin_pinned=false
    if [ ! -r "${VERSIONS_FILE}" ]; then
        echo "${VERSIONS_FILE} を読み込めません" >&2
        return 1
    fi
    while IFS= read -r line || [ -n "${line}" ]; do
        [[ "${line}" =~ ^[[:space:]]*$ || "${line}" = "---" ]] && { comment_pinned=false; continue; }
        # 直前に続くコメント行に「固定」があるかを覚えておく（空行やコメント以外の行で区切る）
        if [[ "${line}" =~ ^[[:space:]]*# ]]; then
            [[ "${line}" == *固定* ]] && comment_pinned=true
            continue
        fi
        pinned=${comment_pinned}
        comment_pinned=false
        [[ "${line}" == *"#"*固定* ]] && pinned=true

        if [[ "${line}" =~ ^([a-z0-9_]+):[[:space:]]*\"([^\"]*)\" ]]; then
            section=""
            [ "${pinned}" = true ] || check_scalar "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        elif [[ "${line}" =~ ^([a-z0-9_]+):[[:space:]]*(#.*)?$ ]]; then
            section="${BASH_REMATCH[1]}"
        elif [ "${section}" = "neovim_plugins" ] && [[ "${line}" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]*\"([^\"]*)\" ]]; then
            plugin_name="${BASH_REMATCH[1]}"
            plugin_pinned=${pinned}
        elif [ "${section}" = "neovim_plugins" ] && [[ "${line}" =~ ^[[:space:]]+version:[[:space:]]*\"([^\"]*)\" ]]; then
            if [ -n "${plugin_name}" ] && [ "${plugin_pinned}" = false ] && [ "${pinned}" = false ]; then
                check_neovim_plugin "${plugin_name}" "${BASH_REMATCH[1]}"
            fi
            plugin_name=""
        elif [ -n "${section}" ] && [[ "${line}" =~ ^[[:space:]]+-[[:space:]]+\"([^\"]*)\" ]]; then
            [ "${pinned}" = true ] || check_list_item "${section}" "${BASH_REMATCH[1]}"
        else
            # 形式に合わない行を黙って読み飛ばすとチェック漏れに気付けないため、報告する
            failed+=("解釈できない行: ${line}")
        fi
    done < "${VERSIONS_FILE}"

    local item
    echo "# ${VERSIONS_FILE#"${REPO_DIR}/"} のチェック結果（$(date '+%Y-%m-%d %H:%M') 時点、scripts/check-versions.sh）"
    if [ "${#outdated[@]}" -eq 0 ]; then
        echo "古いバージョンはありません"
    else
        echo "新しいバージョンがあるもの:"
        for item in "${outdated[@]}"; do
            echo "- ${item}"
        done
    fi
    if [ "${#failed[@]}" -gt 0 ]; then
        echo "最新版を取得できなかったもの:"
        for item in "${failed[@]}"; do
            echo "- ${item}"
        done
    fi
}

# 結果を表示し、キャッシュに保存する（途中で失敗しても壊れたキャッシュを残さないよう、一時ファイル経由で置き換える）
check_and_cache() {
    local tmp
    mkdir -p "${CACHE_DIR}"
    tmp="$(mktemp "${CACHE_DIR}/outdated.XXXXXX")"
    # run_check は同じシェルで動くので、終わった後に succeeded と failed を参照できる
    if ! run_check > "${tmp}"; then
        rm -f "${tmp}"
        return 1
    fi
    cat "${tmp}"
    if [ "${succeeded}" -eq 0 ]; then
        # 1 件も取得できなかった（オフラインなど）ときは、前回の結果を残す
        rm -f "${tmp}"
        echo "最新版を 1 件も取得できなかったため、キャッシュは更新していません" >&2
        return 1
    fi
    mv "${tmp}" "${CACHE_FILE}"
    if [ "${fetch_failed}" -gt 0 ]; then
        # 通信などで取得できなかったものがあるときは、更新日時を古くして次のセッションで再チェックさせる
        # （調べ先が未定義・解釈できない行は再チェックしても変わらないため、きっかけにしない）
        touch -t 200001010000 "${CACHE_FILE}"
    fi
}

cache_is_stale() {
    [ ! -f "${CACHE_FILE}" ] \
        || [ "${VERSIONS_FILE}" -nt "${CACHE_FILE}" ] \
        || [ -n "$(find "${CACHE_FILE}" -mtime +$((CACHE_MAX_AGE_DAYS - 1)) 2>/dev/null)" ]
}

# 裏で再チェックする。多重起動しないよう、ロック用ディレクトリを作れたときだけ実行する
refresh_in_background() {
    local pid
    mkdir -p "${CACHE_DIR}"
    # ロックを持つプロセスが異常終了などでいなくなっていれば、ロックを外す
    # 生きていても 1 時間たっていれば固まったとみなし、止めてから外す
    # （PID がまだ書かれていない作成直後のロックは実行中とみなし、1 時間たっても PID がなければ外す）
    if pid=$(cat "${LOCK_DIR}/pid" 2>/dev/null); then
        if ! kill -0 "${pid}" 2>/dev/null; then
            rm -rf "${LOCK_DIR}"
        elif [ -n "$(find "${LOCK_DIR}" -maxdepth 0 -mmin +60 2>/dev/null)" ]; then
            # 再起動などで PID が別のプロセスに再利用されている場合は止めない
            case "$(ps -p "${pid}" -o command= 2>/dev/null)" in
                *check-versions.sh*) kill "${pid}" 2>/dev/null || true ;;
            esac
            rm -rf "${LOCK_DIR}"
        fi
    elif [ -n "$(find "${LOCK_DIR}" -maxdepth 0 -mmin +60 2>/dev/null)" ]; then
        rm -rf "${LOCK_DIR}"
    fi
    mkdir "${LOCK_DIR}" 2>/dev/null || return 0
    # 前回の再チェックが途中で止まった場合の一時ファイルを消す（ロック中は他に実行中のものはない）
    rm -f "${CACHE_DIR}"/outdated.??????
    (
        # セッション側の終了に巻き込まれないよう HUP を無視する
        trap '' HUP
        check_and_cache || true
        rm -rf "${LOCK_DIR}"
    ) </dev/null >/dev/null 2>&1 &
    # 先に終わってロックが消えていれば書き込みは失敗するが、問題ない
    echo "$!" 2>/dev/null > "${LOCK_DIR}/pid" || true
}

session_start() {
    if [ -f "${CACHE_FILE}" ] && grep -q '^- ' "${CACHE_FILE}"; then
        cat "${CACHE_FILE}"
    fi
    if cache_is_stale; then
        refresh_in_background
    fi
}

case "${1:-}" in
    --session-start) session_start ;;
    "") check_and_cache ;;
    *)
        echo "usage: $0 [--session-start]" >&2
        exit 1
        ;;
esac
