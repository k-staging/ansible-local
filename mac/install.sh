#!/bin/bash
CURRENT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
USER_NAME="$(whoami)"
USER_HOME="/Users/${USER_NAME}"
ANSIBLE_DIR="${CURRENT_DIR}/../.ansible"

# ベースの install.sh を読み込む
source ../.ansible/install.sh

# 各種処理実行
sudo_settings
run_ansible

