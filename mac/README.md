# Mac ローカル環境構築

### 対象バージョン
macOS Big Sur ( バージョン 11.4 )  で動作確認済みです。

### セットアップ
まずはhomebrewをインストールして下さい。  
M1 Mac を使っている場合は、先頭に arch コマンドをつけて実行します。  
```
###########################################
# Intel Mac の brew インストールコマンド
###########################################
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

########################################
# M1 Mac の brew インストールコマンド
########################################
# M1 Mac の場合は事前に、 ターミナル.app -> 右クリック -> "情報を見る" -> "Rosettaを使用して開く" にチェックをつけておいて下さい
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
# init.sh 実行
##################
bash install.sh
```

