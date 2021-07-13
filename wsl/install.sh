#!/usr/bin/env bash
CURRENT_DIR="$(cd $(dirname 0) && pwd)"
USER_NAME="$(/mnt/c/Windows/System32/whoami.exe |awk -F "\\" '{print $NF}' | sed -e "s/[\r\n]\+//g")"
USER_HOME="/home/${USER_NAME}"
ANSIBLE_DIR="~/src/ansible_playbooks/.ansible"
source ../.ansible/install.sh

# wsl で使うためのユーザーを作成する
create_user() {
    sudo su - root -c "$(cat << EOF
    useradd -s /bin/bash ${USER_NAME}
    mkdir -p ${USER_HOME}/{src,.ssh}
    chmod 700 ${USER_HOME}/.ssh
    if [ -e /mnt/c/Users/${USER_NAME}/.ssh/id_rsa ]; then
        cat /mnt/c/Users/${USER_NAME}/.ssh/id_rsa > ${USER_HOME}/.ssh/id_rsa
        chmod 600 /home/${USER_NAME}/.ssh/id_rsa
    fi
    if [ -e /mnt/c/Users/${USER_NAME}/.ssh/id_rsa.pub ]; then
        cat /mnt/c/Users/${USER_NAME}/.ssh/id_rsa.pub > ${USER_HOME}/.ssh/id_rsa.pub
    fi
    cp -a ${CURRENT_DIR}/../../ansible_playbooks ${USER_HOME}/src/
    chown -R ${USER_NAME}:${USER_NAME} ${USER_HOME}
EOF
)"
}

# pyenv 実行に必要なパッケージをインストール
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
        libncurses5 \
        libncurses5-dev \
        libncursesw5 \
        make \
        openssl \
        python-apt \
        python3-apt \
        python3-dev \
        sqlite3 \
        zlib1g-dev
EOF
)"
}

# 各種処理実行
create_user
install_apt_pkg
sudo_settings
run_ansible

