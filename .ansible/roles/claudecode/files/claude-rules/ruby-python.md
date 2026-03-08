---
paths:
  - "**/*.rb"
  - "**/*.py"
  - "**/*.rake"
  - "**/*.gemspec"
---
# Ruby / Python ルール

## 編集前
- `backend-dev` Skill を呼び出すこと

## Rails プロジェクトの場合（編集後レビュー）
- `rails-code-reviewer` でコード品質チェック
- `rails-security-auditor` でセキュリティチェック
- `db/migrate/` 変更時は `rails-db-migration-reviewer` で安全性確認
- `spec/` 変更時は `rails-test-guardian` でテスト実行
