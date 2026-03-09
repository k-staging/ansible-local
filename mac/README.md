# Mac ローカル環境構築

### 対象バージョン
macOS Sequoia ( バージョン 15.x ) で動作確認済みです。

### セットアップ
まずはhomebrewをインストールして下さい。  
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
以下を順番に実行します。  
```
###########################
# このリポジトリを clone
###########################
mkdir ~/src
git clone https://github.com/k-staging/ansible-local.git ~/src/ansible-local
cd ~/src/ansible-local/mac

##################
# install.sh 実行
##################
bash install.sh
```

