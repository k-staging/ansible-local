# Claude Code YOLO モード環境

Neovimで Claude Code の YOLO モード（自動承認モード）を安全に使用するための開発コンテナ環境です。

## 概要

この環境は、Anthropic公式の [claude-code/.devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer) をベースに、Neovim対応にカスタマイズしています。

### 主な特徴

- **完全なコンテナ隔離**: Neovim自体がコンテナ内で動作
- **ファイアウォール保護**: ホワイトリスト方式の厳格な通信制限
- **公式ベストプラクティス準拠**: VSCodeと同じdevcontainer.json使用
- **セキュアなYOLOモード**: 危険な操作を隔離環境で実行

### セキュリティ機能

- **ネットワーク制限**: GitHub、npm、Anthropic など許可されたドメインのみ通信可能
- **非rootユーザー実行**: nodeユーザー(非特権)で動作
- **ファイアウォール自動設定**: コンテナ起動時に自動的にiptablesルール適用

## セットアップ

### 前提条件

- Docker または Docker Desktop がインストール済み
- Ansible実行でこのロールが適用済み

### インストール確認

```bash
# devcontainer.vim がインストールされているか確認
which devcontainer.vim

# テンプレートが配置されているか確認
ls ~/.config/claude-yolo-template/.devcontainer
```

## 使い方

### 1. プロジェクトにテンプレートをコピー

```bash
cd your-project
cp -r ~/.config/claude-yolo-template/.devcontainer ./
```

### 2. コンテナ起動 + Neovim実行

```bash
# カレントディレクトリでコンテナ起動してNeovimを開く
devcontainer.vim start . --nvim
```

初回起動時はDockerイメージのビルドに数分かかります。

### 3. コンテナ内でClaude Code YOLO起動

Neovim内で:

```vim
" ターミナルを開く
<Ctrl-t>

" ターミナル内でClaude Code YOLOモード起動
claude --dangerously-skip-permissions

" または通常のClaude Codeを起動してから確認スキップ
claude
```

### 4. コンテナ停止

```bash
# 別のターミナルで
devcontainer.vim stop .

# コンテナを完全に削除
devcontainer.vim down .
```

## devcontainer.vim コマンド一覧

```bash
# コンテナ起動
devcontainer.vim start .

# コンテナ起動 + Neovim実行
devcontainer.vim start . --nvim

# コンテナ停止
devcontainer.vim stop .

# コンテナ削除
devcontainer.vim down .

# コンテナ状態確認
docker ps -a | grep devcontainer

# テンプレートから設定生成
devcontainer.vim templates apply
```

## 設定ファイル

### Dockerfile

- Node.js 20ベース
- Neovim、fzf、git-delta などインストール
- デフォルトエディタ: Neovim
- デフォルトシェル: zsh

### devcontainer.json

- ネットワーク管理権限: `NET_ADMIN`, `NET_RAW`
- ボリュームマウント: コマンド履歴、Claude設定
- 起動時処理: ファイアウォール初期化

### devcontainer.vim.json

- Neovim設定をコンテナにマウント (読み取り専用)
- ホストの `~/.config/nvim` をコンテナ内で使用

### init-firewall.sh

- iptables/ipsetでホワイトリスト方式のファイアウォール設定
- 許可ドメイン: GitHub、npm、Anthropic、Sentry、VS Code など

## トラブルシューティング

### コンテナが起動しない

```bash
# Dockerが起動しているか確認
docker ps

# ログを確認
docker logs <container-id>

# コンテナを削除して再起動
devcontainer.vim down .
devcontainer.vim start . --nvim
```

### ファイアウォールでブロックされる

意図的にホワイトリスト方式で厳格に制限しています。
必要なドメインがある場合は `init-firewall.sh` を編集:

```bash
# .devcontainer/init-firewall.sh の ALLOWED_DOMAINS に追加
ALLOWED_DOMAINS=(
  "github.com"
  "api.github.com"
  # ... 既存のドメイン ...
  "your-domain.com"  # 追加
)
```

### Neovim設定が反映されない

devcontainer.vim.json の `localSettingsPath` を確認:

```json
{
  "localSettingsPath": "~/.config/nvim"
}
```

ホストの `~/.config/nvim` が読み取り専用でマウントされます。

### Claude Code が見つからない

コンテナ内で確認:

```bash
# コンテナ内のシェルに入る
docker exec -it <container-id> zsh

# Claude Codeがインストールされているか確認
which claude

# npmグローバルパッケージ確認
npm list -g --depth=0
```

## カスタマイズ

### タイムゾーン変更

`.devcontainer/devcontainer.json`:

```json
{
  "build": {
    "args": {
      "TZ": "America/New_York"  // 変更
    }
  }
}
```

### Claude Code バージョン固定

`.devcontainer/devcontainer.json`:

```json
{
  "build": {
    "args": {
      "CLAUDE_CODE_VERSION": "1.0.24"  // 特定バージョン
    }
  }
}
```

### 追加パッケージインストール

`.devcontainer/Dockerfile`:

```dockerfile
# Neovimの後に追加
RUN apt-get update && apt-get install -y \
  your-package \
  && rm -rf /var/lib/apt/lists/*
```

## 通常モードとYOLOモードの使い分け

| 用途 | モード | 環境 | コマンド |
|------|--------|------|----------|
| 日常的なコーディング | 通常 | ホスト | `nvim` |
| 実験的な変更 | YOLO | コンテナ | `devcontainer.vim start . --nvim` |
| 大規模リファクタリング | YOLO | コンテナ | `devcontainer.vim start . --nvim` |
| 信頼できないプロジェクト | YOLO | コンテナ | `devcontainer.vim start . --nvim` |

## 参考リンク

- [Claude Code 公式ドキュメント](https://docs.claude.com/claude-code)
- [公式 .devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
- [devcontainer.vim](https://github.com/mikoto2000/devcontainer.vim)
- [YOLO モードガイド](https://apidog.com/blog/claude-code-gemini-yolo-mode/)

## ライセンス

このテンプレートは Anthropic の公式 .devcontainer をベースにしています。
