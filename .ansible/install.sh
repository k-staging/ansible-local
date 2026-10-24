#!/bin/bash
set -euo pipefail

# CURRENT_DIRが未定義の場合は自動設定
if [ -z "${CURRENT_DIR:-}" ]; then
    CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
fi

# ANSIBLE_DIRが未定義の場合は自動設定
if [ -z "${ANSIBLE_DIR:-}" ]; then
    # このスクリプトが .ansible ディレクトリ内にある場合
    if [ "$(basename ${CURRENT_DIR})" = ".ansible" ]; then
        ANSIBLE_DIR="${CURRENT_DIR}"
    else
        ANSIBLE_DIR="${CURRENT_DIR}/../.ansible"
    fi
fi

eval $(grep python3_version ${ANSIBLE_DIR}/inventory)
PYTHON3_VERSION=${python3_version}
UV_VERSION="0.4.25"

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
    if [ ! -e ~/.cargo/bin/uv ]; then
        curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh
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
    uv pip install --python "\${UV_PYTHON_PATH}" --break-system-packages \
        ansible>=11.9.0 \
        neovim>=0.3.1 \
        pynvim>=0.5.0 \
        python-lsp-server>=1.12.0 \
        sqlparse>=0.5.0

    # binファイルへのシンボリックリンクを作成
    UV_PYTHON_BIN_DIR=\$(dirname "\${UV_PYTHON_PATH}")
    for cmd in ansible ansible-playbook ansible-galaxy pylsp sqlformat; do
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
