# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## リポジトリ概要

このリポジトリは、macOSおよびWSL（Windows Subsystem for Linux）の開発環境をセットアップするためのAnsibleベースの構成管理リポジトリです。プログラミング言語環境、エディタ、ユーティリティなど、様々な開発ツールのインストールと設定にAnsibleロールを使用しています。

## よく使うコマンド

### インストール
```bash
# macOSの場合
cd mac && bash install.sh

# WSL/Ubuntuの場合
cd wsl && bash install.sh
```

### 特定のロールの実行
```bash
# タグを使って特定のロールを実行
ansible-playbook .ansible/site.yml -i .ansible/inventory --tags "nodenv,tmux"

# すべてのロールを実行
ansible-playbook .ansible/site.yml -i .ansible/inventory
```

### 手動でのAnsible実行
```bash
# .ansibleディレクトリから
cd .ansible
~/.pyenv/versions/3.11.10/bin/ansible-playbook site.yml -i inventory
```

## アーキテクチャ

### ディレクトリ構造
- `/.ansible/` - Ansibleのコア設定
  - `site.yml` - すべてのロールを統括するメインプレイブック
  - `inventory` - バージョン定義: Python 3.11.10、Ruby 3.2.2、Node 18.20.4、Go 1.17.13
  - `roles/` - 個別の設定ロール
  - `install.sh` - ベースインストールスクリプト
- `/mac/` - macOS専用セットアップラッパー
- `/wsl/` - WSL専用セットアップラッパー

### Ansibleロール
1. **common** - 基本システムパッケージと設定
2. **nodenv** - Node.js環境（Claude Code CLIなどのnpmパッケージを含む）
3. **rbenv** - Ruby環境管理
4. **goenv** - Go環境管理
5. **neovim** - Neovimエディタ設定
6. **tmux** - ターミナルマルチプレクサセットアップ

### 主要なパターン
- システムパッケージの代わりに*envツールを使用した言語バージョン管理
- MacとUbuntu/Debian固有のタスクに`ansible_distribution`によるプラットフォーム検出を使用
- ローカル接続モード - Ansibleが実行されているマシン自体を設定
- バージョンは`.ansible/inventory`で一元管理

## 開発ワークフロー

1. `.ansible/roles/<role_name>/`内のロールファイルを変更
2. タグを使って特定のロールを実行して変更をテスト
3. インストールスクリプトはpyenvのセットアップとAnsibleのインストールを自動的に処理
4. WSLの場合、設定後にポストタスクでWSLインスタンスを再起動

## 最近の更新
リポジトリに最近Claude Code CLI (`@anthropic-ai/claude-code@1.0.24`) がnodenvロール経由でインストールされるnpmパッケージに追加されました。