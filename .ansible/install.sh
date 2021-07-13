#!/bin/bash
eval $(grep python3_version ${CURRENT_DIR}/../.ansible/inventory)
eval $(grep pip_version ${CURRENT_DIR}/../.ansible/inventory)
PYTHON3_VERSION=${python3_version}
PIP_VERSION=${pip_version}

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
    # init.sh 再実行時に tmux を起動してしまう為、 .bash_profile は一旦削除する
    rm -f ${USER_HOME}/.bash_profile
    # pyenv セットアップと ansible の実行
    sudo su - ${USER_NAME} -c "$(cat << EOF
    if [ ! -e ~/.pyenv ]; then
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
        ~/.pyenv/bin/pyenv install ${PYTHON3_VERSION} && ~/.pyenv/bin/pyenv global ${PYTHON3_VERSION} && ~/.pyenv/bin/pyenv rehash
    fi
    ~/.pyenv/versions/${PYTHON3_VERSION}/bin/pip install pip==${PIP_VERSION}
    ~/.pyenv/versions/${PYTHON3_VERSION}/bin/pip install -r ${ANSIBLE_DIR}/requirements.txt
    PATH="/usr/sbin:$PATH" && ~/.pyenv/versions/${PYTHON3_VERSION}/bin/ansible-playbook ${ANSIBLE_DIR}/site.yml -i ${ANSIBLE_DIR}/inventory
EOF
)"
}

