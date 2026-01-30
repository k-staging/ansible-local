# CRITICAL RULES - MUST ALWAYS FOLLOW

These rules apply to ALL projects and MUST be followed without exception.
以下のルールは全プロジェクトに適用され、例外なく必ず守ること。

## 1. TodoWrite - ALWAYS USE
**MUST use TodoWrite for ANY task** involving:
- Investigation / 調査
- Implementation / 実装
- Modification / 修正
- Multi-step work / 複数ステップの作業

**ONLY skip for**: Simple yes/no questions or single-line answers.
**例外**: はい/いいえで答えられる質問、または1行で回答できる質問のみ。

## 2. Skills - INVOKE BEFORE EDITING
**MUST invoke the corresponding Skill BEFORE editing these files**:

| File Pattern | Skill to Invoke |
|-------------|-----------------|
| `.rb`, `.py`, `.sql` | `backend-dev` |
| `Dockerfile`, `docker-compose*.yml`, `.ansible/`, `*.tf`, k8s manifests | `infra-quick-check` |
| ActiveRecord queries, raw SQL | `sql-helper` |

## 3. Agents - RUN AFTER COMPLETION
**MUST run review agents after completing all todos**:
- Ansible changes → `ansible-validator`, `infra-reviewer`
- Rails changes → `rails-code-reviewer`, `rails-security-auditor`

## 4. Language
すべての回答は日本語で行う。

---

# Claude Code グローバル設定

## 基本設定
- Claude Code による回答は、必ず日本語でお願いします。
- コマンドを提示する際は、必ず一行で記述すること（コピーしやすくするため）。複数行に分割しない。

## 編集モード（Shift+Tab で切り替え）

### 📋 Plan Mode（Shift+Tab 2回）
**複雑なタスクの実装前に詳細な計画を立てるモード**

#### いつ使うべきか
- 新機能の追加（複数ファイルにまたがる変更）
- アーキテクチャの変更
- リファクタリング（影響範囲が広い）
- 複雑なバグ修正
- データベーススキーマの変更

#### 使い方
1. Shift+Tab を2回押して Plan Mode に切り替え
2. 具体的な指示を伝える（例: "会社紹介Webサイトを作成。トップページには会社概要、サービス紹介、お問い合わせフォームを設置"）
3. AIが作成した計画を確認し、必要に応じて修正を指示
4. 計画承認後、Edit automatically モードに切り替えて実装開始

#### Plan Mode を使わない場合
- 単純なファイル修正（1〜2ファイル）
- タイポ修正
- ドキュメントの更新
- 明確で単純なタスク

### ⚡ Edit automatically（Shift+Tab 1回）
**ファイル編集を自動的に承認し、作業を高速化するモード**

#### いつ使うべきか
- Plan Mode で計画を承認した後の実装
- 実装方針が決まった作業
- テストコード追加
- リファクタリング実行
- 同じパターンの修正を複数ファイルに適用

#### メリット
- 作業効率が大幅に向上
- 信頼できる範囲の作業をスムーズに進行可能
- いつでも Shift+Tab で Ask before edits に戻せる

#### 注意点
- **Git管理が必須**（意図しない変更をrevertできるように）
- 意図しない変更に気づきにくい
- 不安な場合は Esc キーで中断可能
- 慣れないうちは Ask before edits のままでOK

### 🔄 理想的なワークフロー

```
1. Plan Mode (Shift+Tab 2回)
   ↓ 計画を立て、承認を得る

2. Edit automatically (Shift+Tab 1回)
   ↓ 高速実装

3. Agent でレビュー
   ↓ 品質・セキュリティチェック

4. Git commit
```

## ワークフロールール

### タスク管理（TodoWrite）

**すべてのタスクでTodoWriteを使用する**（単純な質問への回答を除く）

#### 基本フロー
1. タスク開始時にTodoWriteでタスクリストを作成
2. 作業中のタスクを `in_progress` にマーク
3. 完了したタスクは即座に `completed` にマーク
4. 全タスク完了後、サブエージェントでレビューを実施

#### なぜ常に使うのか
- タスクの進捗をユーザーに可視化できる
- 複雑なタスクでも抜け漏れを防げる
- 「全タスク完了」のタイミングが明確になり、レビューエージェントの起動忘れを防げる

### 基本方針：Skillファースト（予防型）+ Agent（検証型）

1. **Skill（自動起動）**: 実装中にリアルタイムで問題を予防
2. **Agent（明示的起動）**: 完成後に総合的なレビューで検証

この二段構えで、手戻りを最小化し、高品質なコードを効率的に実現します。

### 🎯 Skill（実装中のアシスト）

以下のファイルを編集する**直前**に、対応するSkillを必ず呼び出す：

#### backend-dev
- **対象ファイル**: `.rb`, `.py`, `.sql`
- **役割**: ベストプラクティス適用、N+1防止、簡単なバグ修正
- **ツール**: Read, Edit, Grep, Glob

#### infra-quick-check
- **対象ファイル**: `Dockerfile`, `docker-compose*.yml`, `.ansible/`配下, `*.tf`, k8s manifest
- **役割**: 構文チェック、基本的なセキュリティチェック
- **ツール**: Read, Grep, Glob

#### sql-helper
- **対象コード**: ActiveRecordクエリ、生SQLクエリ
- **役割**: N+1問題防止、インデックス提案、クエリ最適化
- **ツール**: Read, Grep, Glob

**重要**: Skillsは「自動起動」ではなく、Claudeが判断して明示的に呼び出す。上記の対象ファイル・コードを編集する際は必ず起動すること。

### 🔍 Agent（完成後の総合レビュー）

TODOリストの全タスクが完了したら、**必ずサブエージェントを使ってコードレビューを実施する**

#### Ansibleファイルのレビュー（.ansible/roles/配下を変更した場合）
1. `ansible-validator` サブエージェントで構文・ベストプラクティスをチェック
2. `infra-reviewer` サブエージェントでセキュリティ・保守性をレビュー
3. 問題があれば修正してから次へ進む

#### Railsファイルのレビュー（Railsプロジェクトを変更した場合）
1. **コード品質**: `rails-code-reviewer` サブエージェントでRails規約・アンチパターンをチェック
2. **セキュリティ**: `rails-security-auditor` サブエージェントで脆弱性を検出
3. **パフォーマンス** (必要に応じて): `rails-performance-optimizer` サブエージェントでN+1問題等を検出
4. **マイグレーション** (db/migrate/変更時): `rails-db-migration-reviewer` サブエージェントで安全性を確認
5. **テスト** (spec/変更時): `rails-test-guardian` サブエージェントでテストを実行

#### ドキュメント更新
- コード変更後、`docs-updater` サブエージェントで関連ドキュメント(README、CLAUDE.md等)を更新

#### レビューの基本フロー
1. 変更したファイルの一覧を表示
2. 適切なサブエージェントを起動してレビュー実施
3. サブエージェントの指摘事項を確認・修正
4. 変更内容の要約を提示

### 📊 Skill vs Agent 役割分担

| 項目 | Skill（自動） | Agent（明示的） |
|------|--------------|----------------|
| **タイミング** | 実装中（リアルタイム） | 完成後（総合レビュー） |
| **目的** | 予防・早期発見 | 検証・詳細分析 |
| **スコープ** | 局所的（記述中のコード） | 全体的（アーキテクチャ含む） |
| **処理** | 軽量（即座フィードバック） | 重量（詳細チェック） |
| **実行** | メイン会話内 | サブプロセス |
| **例** | N+1警告、構文エラー指摘 | セキュリティ監査、テスト実行 |

### 効率化ルール
- コミットメッセージは変更内容から自動生成する
- 複数ファイルの読み込みや検索は並列で実行する
- overview → symbol → 詳細と段階的に情報収集し、既読ファイルは再読み込みしない

### テスト実行ルール
#### テストファイルを編集した場合
1. **即座にテストを実行する（ユーザーに依頼しない）**
   - 編集したテストファイルを実行
   - 例: `bundle exec rspec <編集したファイルパス>` (Rails/RSpec)
2. テスト結果をユーザーに報告する
3. 失敗した場合は原因を調査し、修正する

#### 実装ファイルを編集した場合
1. **関連するテストを実行する（ユーザーに依頼しない）**
   - 例: `bundle exec rspec spec/<関連するテストファイル>` (Rails/RSpec)
2. テスト結果をユーザーに報告する

### 変更の原則
- 明示的に依頼されない限り、不要なリファクタリングは避ける
- 変更前に影響範囲を調査し、既存テストの有無を確認
- プロジェクトのコーディング規約・ディレクトリ構造に従う
- コード変更時は関連ドキュメント（README、CLAUDE.md等）も必要に応じて更新

### ファイル削除時の確認ルール

ファイルを削除した場合、**必ず以下の関連箇所を確認・修正する**：

#### 確認すべき項目
1. **インポート/require文** - 削除したファイルを参照しているコード
2. **設定ファイル** - ルーティング、設定、マニフェスト等での参照
3. **テストファイル** - 削除したファイルに対応するテスト
4. **ドキュメント** - README、CLAUDE.md等での言及
5. **依存関係** - package.json、Gemfile等での参照（該当する場合）

#### 確認手順
```
1. Grepで削除したファイル名・クラス名・関数名を検索
2. 見つかった参照を全て修正または削除
3. ビルド/テストを実行して参照エラーがないことを確認
```

#### 注意
- 削除前に `find_referencing_symbols` や `Grep` で参照箇所を洗い出す
- 参照が多い場合はTodoWriteでチェックリストを作成して漏れを防ぐ

### ドキュメント更新の原則
- **プロジェクトCLAUDE.md**（リポジトリ直下やプロジェクトルート）はチーム全体に影響するため、**必ずユーザーに確認してから更新する**
- **グローバルCLAUDE.md**（~/.claude/CLAUDE.md）は個人設定なので自由に更新可能
- プロジェクトREADME.mdも重要なドキュメントのため、更新前に変更内容を提示する
- ロール配下のREADMEやドキュメントは、変更が明確な場合のみ自動更新可

### PRディスクリプション
- PRのディスクリプションを考える時は、PRテンプレートがある場合は必ずテンプレートを参考にすること

### エラー対応
- エラーが発生したら即座に報告し、対処方法をユーザーと相談
- 繰り返し同じエラーで失敗する場合は、別のアプローチを提案
