#!/bin/bash
set -euo pipefail

# CURRENT_DIRが未定義の場合は自動設定
if [ -z "${CURRENT_DIR:-}" ]; then
    CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
fi

# ANSIBLE_DIRが未定義の場合は自動設定
if [ -z "${ANSIBLE_DIR:-}" ]; then
    # このスクリプトが ansible ディレクトリ内にある場合
    if [ "$(basename ${CURRENT_DIR})" = "ansible" ]; then
        ANSIBLE_DIR="${CURRENT_DIR}"
    else
        ANSIBLE_DIR="${CURRENT_DIR}/../ansible"
    fi
fi

# バージョンは group_vars/all/versions.yml から読み込む
VERSIONS_FILE="${ANSIBLE_DIR}/group_vars/all/versions.yml"
# 行末コメントがあっても値だけを取り出す。pip パッケージは >= などがリダイレクトにならないよう "..." で囲む
PYTHON3_VERSION=$(sed -n 's/^python3_version: *"\([^"]*\)".*$/\1/p' "${VERSIONS_FILE}")
UV_VERSION=$(sed -n 's/^uv_version: *"\([^"]*\)".*$/\1/p' "${VERSIONS_FILE}")
PIP_PACKAGES=$(sed -n '/^pip_packages:/,/^[^ ]/s/^  - "\([^"]*\)".*$/"\1"/p' "${VERSIONS_FILE}" | tr '\n' ' ')
if [ -z "${PYTHON3_VERSION}" ] || [ -z "${UV_VERSION}" ] || [ -z "${PIP_PACKAGES}" ]; then
    echo "failed to read versions from ${VERSIONS_FILE}" >&2
    exit 1
fi

# USER_NAMEとUSER_HOMEが未定義の場合は自動設定
if [ -z "${USER_NAME:-}" ]; then
    USER_NAME="$(whoami)"
fi
if [ -z "${USER_HOME:-}" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        USER_HOME="/Users/${USER_NAME}"
    else
        USER_HOME="/home/${USER_NAME}"
    fi
fi

sudo_settings() {
    if [ -f /etc/sudoers.d/ansible_user ]; then
        echo "sudo is already"
    else
        echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible_user
        sudo chmod 440 /etc/sudoers.d/ansible_user
        sudo chown root /etc/sudoers.d/ansible_user
    fi
}

run_ansible() {
    # install.sh 再実行時に tmux を起動してしまう為、 .bash_profile は一旦削除する
    rm -f ${USER_HOME}/.bash_profile
    # uv セットアップと ansible の実行
    sudo su - ${USER_NAME} -c "$(cat << EOF
    set -euo pipefail
    # uv のインストール（バージョン固定）
    # バージョンが異なる場合も入れ直す。インストール先は従来どおり ~/.cargo/bin に固定する
    if [ "\$(~/.cargo/bin/uv --version 2>/dev/null | cut -d' ' -f2)" != "${UV_VERSION}" ]; then
        curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | UV_INSTALL_DIR="\$HOME/.cargo/bin" sh
    fi

    # PATH に uv を追加
    export PATH="\$HOME/.cargo/bin:\$PATH"

    # Python のインストール
    uv python install ${PYTHON3_VERSION}

    # python3 コマンドへのシンボリックリンクを作成
    # uvでインストールしたPythonを python3 として使えるようにする
    mkdir -p ~/.local/bin
    UV_PYTHON_PATH=\$(uv python find ${PYTHON3_VERSION})
    ln -sf "\${UV_PYTHON_PATH}" ~/.local/bin/python3

    # グローバルにPythonパッケージをインストール
    uv pip install --python "\${UV_PYTHON_PATH}" --break-system-packages ${PIP_PACKAGES}

    # binファイルへのシンボリックリンクを作成
    UV_PYTHON_BIN_DIR=\$(dirname "\${UV_PYTHON_PATH}")
    for cmd in ansible ansible-playbook ansible-galaxy pylsp sqlformat ruff; do
        if [ -f "\${UV_PYTHON_BIN_DIR}/\${cmd}" ]; then
            ln -sf "\${UV_PYTHON_BIN_DIR}/\${cmd}" ~/.local/bin/\${cmd}
        fi
    done

    # Ansible の実行
    sudo mkdir -p /usr/local/bin
    export PATH="\$HOME/.local/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/opt/homebrew/bin" && \
    ansible-playbook ${ANSIBLE_DIR}/site.yml -i ${ANSIBLE_DIR}/inventory
EOF
)"
}

# このスクリプトが直接実行された場合のみ、処理を実行
# source された場合は、呼び出し側で実行する
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    sudo_settings
    run_ansible
fi
