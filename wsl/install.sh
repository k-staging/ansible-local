#!/usr/bin/env bash
CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
USER_NAME="$(/mnt/c/Windows/System32/whoami.exe |awk -F "\\" '{print $NF}' | sed -e "s/[\r\n]\+//g")"
USER_HOME="/home/${USER_NAME}"
ANSIBLE_DIR="${CURRENT_DIR}/../.ansible"
REPO_DIR="$(cd "${CURRENT_DIR}/.." && pwd)"

# ベースの install.sh を読み込む
source ../.ansible/install.sh

# wsl で使うためのユーザーを作成する
create_user() {
    sudo su - root -c "$(cat << EOF
    id -u ${USER_NAME} >/dev/null 2>&1 || useradd -s /bin/bash ${USER_NAME}
    mkdir -p ${USER_HOME}/{src,.ssh}
    chmod 700 ${USER_HOME}/.ssh
    if [ -e /mnt/c/Users/${USER_NAME}/.ssh/id_rsa ]; then
        cat /mnt/c/Users/${USER_NAME}/.ssh/id_rsa > ${USER_HOME}/.ssh/id_rsa
        chmod 600 /home/${USER_NAME}/.ssh/id_rsa
    fi
    if [ -e /mnt/c/Users/${USER_NAME}/.ssh/id_rsa.pub ]; then
        cat /mnt/c/Users/${USER_NAME}/.ssh/id_rsa.pub > ${USER_HOME}/.ssh/id_rsa.pub
    fi
    chown -R ${USER_NAME}:${USER_NAME} ${USER_HOME}
EOF
)"
}

# Ansible の実行や言語ランタイムのビルドに必要なパッケージをインストール
install_apt_pkg() {
    sudo su - root -c "$(cat << EOF
    apt update
    apt install -y \
        aptitude \
        build-essential \
        bzip2 \
        gcc \
        git \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libffi-dev \
        libncurses-dev \
        make \
        openssl \
        python3-apt \
        python3-dev \
        sqlite3 \
        zlib1g-dev
EOF
)"
}

# 初回セットアップ時（/root など、作成したユーザーから読めない場所で実行した場合）は
# origin（の既定ブランチ）から ~/src/ansible-local に clone し、そちらの playbook を実行する
clone_repo() {
    local remote_url
    remote_url="$(git -C "${REPO_DIR}" remote get-url origin)"
    sudo su - ${USER_NAME} -c "$(cat << EOF
    if [ ! -d ${USER_HOME}/src/ansible-local ]; then
        GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone '${remote_url}' ${USER_HOME}/src/ansible-local
    fi
EOF
)"
    ANSIBLE_DIR="${USER_HOME}/src/ansible-local/.ansible"
}

# 各種処理実行
create_user
install_apt_pkg
sudo_settings
# リポジトリがユーザーのホーム配下にあれば、そのリポジトリの playbook をそのまま実行する
case "${REPO_DIR}/" in
    "${USER_HOME}/"*) ;;
    *) clone_repo ;;
esac
run_ansible

