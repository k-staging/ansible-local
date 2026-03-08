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

## コーディング規約
- タスク名は英語で簡潔に記述（例: `install packages`, `copy config file`）
- `ansible.builtin.*` の完全修飾コレクション名(FQCN)を使用
- `changed_when` / `failed_when` を適切に設定し、冪等性を保つ
- シークレットは平文で書かない（ansible-vault または変数で管理）
- `ansible_distribution` でプラットフォーム分岐する
