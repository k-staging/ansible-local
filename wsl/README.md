# WSL ローカル環境構築
##### WSL インストール  
PowerShell で以下を実行  
```
PS C:\> Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile ${HOME}\Downloads\Ubuntu20.04.appx -UseBasicParsing
```
PowerShell ( 管理者権限 ) で以下を実行  
```
PS C:\> Dism /online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux
```
以下のメッセージが出力されるので、「Y」を応答 ( Y を応答すると PC が再起動されます )  
```
Deployment Image Servicing and Management tool
Version: xx.x.xxxxx.x

Image Version: xx.x.xxxxx.xxx

機能を有効にしています
[==========================100.0%==========================]
The operation completed successfully.
Restart Windows to complete this operation.
Do you want to restart the computer now? (Y/N)
```
PowerSHell ( 管理者権限 ) で以下を実行  
```
PS C:\> Add-AppxPackage ${HOME}\Downloads\Ubuntu20.04.appx
```
Windows キーを押し、 "ubuntu" と入力後 Enter キーを押す  
WSL が起動し、以下メッセージが出力された事を確認したら、 Ctrl +c でウィンドウを閉じます  
```
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username:
```

##### WSL 環境構築
WSL を起動 ( Windows キーを押し、 "ubuntu" と入力し Enter ) し、以下を実行  
```
$ add-apt-repository -y ppa:git-core/ppa && apt update && apt install -y git
$ mkdir ~/src
$ git clone git@github.com:k-staging/ansible-local.git ~/src/ansible_playbooks
$ cd ~/src/ansible_playbooks/wsl && bash ./install.sh
```

# インストール済みの Ubuntu を初期化したい場合
1.  Ubuntu をアンインストールする  
2. 「サービス」の「LxssManager」を「再起動」する( これをやらないと Ubuntu を再インストールできない )  
3.  Ubuntu をインストールする  
