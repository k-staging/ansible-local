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

## 重要なルール

### ローカル設定変更時の原則
**macOS/WSLのローカル設定を変更・追加する場合は、まずこのリポジトリで管理できないか確認すること。**

- シェル設定、エディタ設定、ツール設定 → 該当するロールに追加
- 新しいツールのインストール → 既存ロールに追加、または新規ロール作成
- Claude Code関連の設定 → `roles/claudecode` に追加

直接ローカルファイルを編集するのではなく、Ansibleで管理することで：
- 複数マシン間で設定を同期できる
- 設定の履歴がGitで追跡できる
- 再セットアップ時に自動適用される

### claudecodeロールの構造
`roles/claudecode/` には Claude Code の設定が集約されている：
- `files/CLAUDE.md` - グローバル CLAUDE.md（~/.claude/CLAUDE.md にコピーされる）
- `files/claude-agents/` - サブエージェント定義
- `files/claude-skills/` - スキル定義
- `templates/settings.json.j2` - Claude Code の settings.json

Claude Code の挙動を変更したい場合は、これらのファイルを修正する。

## 最近の更新
リポジトリに最近Claude Code CLI (`@anthropic-ai/claude-code@1.0.24`) がnodenvロール経由でインストールされるnpmパッケージに追加されました。