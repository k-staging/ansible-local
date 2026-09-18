# WSL ローカル環境構築
##### WSL インストール  
PowerShell ( 管理者権限 ) で以下を実行  
```
PS C:\> wsl --install
```
以下のメッセージが出力されたら、 Ctrl +c でウィンドウを閉じます  
```
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username:
```
PowerShell で以下を実行し、 root で再ログイン  
```
PS C:\> wsl -d Ubuntu -u root --exec /bin/bash
```

##### WSL 環境構築
上記で開いたシェルで、以下を実行  
```
$ add-apt-repository -y ppa:git-core/ppa && apt update && apt install -y git
$ mkdir ~/src
$ git clone https://github.com/k-staging/ansible-local.git ~/src/ansible-local
$ cd ~/src/ansible-local/wsl && bash ./install.sh
```

# インストール済みの Ubuntu を初期化したい場合
1.  Ubuntu をアンインストールする  
2. 「サービス」の「LxssManager」を「再起動」する( これをやらないと Ubuntu を再インストールできない )  
3.  Ubuntu をインストールする  
