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

## 既存コードの踏襲
- **編集前に同ディレクトリ・同モジュールの既存ファイルを最低2つ読む**
- 命名規則、メソッド構成、エラーハンドリングパターンを既存に合わせる
- 既存コードと異なるライブラリやパターンを勝手に導入しない

## Rails プロジェクトの場合（編集後レビュー）
- `rails-code-reviewer` でコード品質チェック
- `rails-security-auditor` でセキュリティチェック
- `db/migrate/` 変更時は `rails-db-migration-reviewer` で安全性確認
- `spec/` 変更時は `rails-test-guardian` でテスト実行

## Rails マイグレーション実行ルール
- `db/migrate/` にファイルを作成・編集した場合、**必ず `bin/rails db:migrate` を実行する**
- 実行後、`db/schema.rb`（または `db/structure.sql`）の差分が生成されていることを確認する
- マイグレーションが失敗した場合は、原因を調査してから修正する
