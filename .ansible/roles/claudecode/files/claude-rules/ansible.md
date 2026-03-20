---
paths:
  - "**/.ansible/**/*.yml"
  - "**/roles/**/*.yml"
  - "**/playbooks/**/*.yml"
---
# Ansible ルール

## 編集前
- `infra-quick-check` Skill を呼び出すこと

## 編集後レビュー
- `ansible-validator` サブエージェントで構文・冪等性をチェック
- `infra-reviewer` サブエージェントでセキュリティ・保守性をレビュー

## 既存コードの踏襲
- **編集前に同ロール・同ディレクトリの既存タスクファイルを最低2つ読む**
- 既存タスクの書き方（モジュールの使い方、変数の命名、タスク名のフォーマット）に合わせる
- 新しいパターンを導入しない（既存と異なる書き方をしたくなったら、まず既存を確認）

## コーディング規約
- タスク名は英語で簡潔に記述（例: `install packages`, `copy config file`）
- `ansible.builtin.*` の完全修飾コレクション名(FQCN)を使用
- `changed_when` / `failed_when` を適切に設定し、冪等性を保つ
- シークレットは平文で書かない（ansible-vault または変数で管理）
- `ansible_distribution` でプラットフォーム分岐する
