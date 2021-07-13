# Mac ローカル環境構築

### 対象バージョン
macOS Big Sur ( バージョン 11.4 )  

### セットアップ
以下コマンドを順次実行してください。  
```
# homebrew インストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# このリポジトリを clone
mkdir ~/src
git clone git@github.com:k-staging/ansible-local.git ~/src/ansible_playbooks
cd ~/src/ansible_playbooks/mac

# init.sh 実行
bash install.sh
```

