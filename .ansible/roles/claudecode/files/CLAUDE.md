<!-- Last reviewed: 2026-03-09 -->

# CRITICAL RULES - MUST ALWAYS FOLLOW

以下のルールは全プロジェクトに適用され、例外なく必ず守ること。

## 0. CLAUDE.md 定期見直し
**セッション開始時に、上部の `Last reviewed` 日付を確認する。**

前回の見直しから1週間以上経過している場合：
1. `~/.claude/projects/` 配下のセッション履歴を確認し、過去1週間のやりとりを分析
2. 繰り返し発生している依頼パターンを特定
3. 自動化・ルール化できそうなものがあれば、ユーザーに提案
4. 承認を得たらこの CLAUDE.md に追記し、`Last reviewed` 日付を更新

## 1. 日本語で回答
すべての回答は日本語で行う。

## 2. 自主的な調査 - DO IT YOURSELF
**調査が必要な場合は、ユーザーに依頼せず自分で行う：**
- ファイルの読み込みが必要 → 自分でReadツールを使って読む
- コードの検索が必要 → 自分でGrep/Globで検索する
- WEB検索で情報が得られそう → 自分でWebSearchで調べる
- ドキュメントの確認が必要 → 自分でWebFetchで取得する

**ユーザーに「〜を確認してください」「〜を教えてください」と聞く前に、まず自分で調査すること。**
調査しても分からない場合のみ、ユーザーに質問する。

## 3. コード修正フロー
コード修正を伴う依頼を受けた場合、以下の手順で進める：

> **🚫 STOP: 最初に必ずブランチを切ること。main/develop への直接コミット・push は git フックで強制ブロックされる。**

### Step 0: ブランチ作成（実装着手前の必須手順）
**この手順を完了するまで、いかなるファイル編集も行わないこと。**

1. 現在のブランチを確認する（main/develop ならブランチが未作成）
2. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` でデフォルトブランチを取得し、PRのベースブランチとして記憶する（セッション開始時の情報より実際のGitHub設定を優先）
3. 同じテーマの既存作業ブランチがあれば再利用を検討する（迷う場合はユーザーに確認）
4. **EnterWorktree ツールで worktree を作成する**（ブランチ名を `name` パラメータに指定。例: `feature/xxx`, `fix/xxx`, `chore/xxx`）
5. **worktree 内にいることを確認 → ブランチ名が main/develop でないことを確認してから** Step 1 に進む

### Step 1: 計画立案
1. **PRテンプレートを検索して読み込む**（Globで `.github/pull_request_template*`, `.github/PULL_REQUEST_TEMPLATE*`, `pull_request_template*` を検索し、見つかったらReadで内容を読む）
2. テンプレートがあればその構成に従い、なければ下記デフォルト構成でPRディスクリプション（概要・変更内容）を**簡潔に**作成
3. **作成したPRディスクリプション（途中版）をユーザーに提示し、問題ないか確認を取る**
4. 承認を得てから修正に着手

```markdown
## 概要
（変更の目的・背景）

## 変更内容
（具体的な変更点をリストで記載）
```

### Step 2: 実装
1. 必要に応じてSkillを呼び出しながらコードを修正
2. 修正完了後、変更ファイル一覧を確認

### Step 3: テスト
1. サブエージェント（`rails-test-guardian`等）またはSkillでテストを実行
2. テストが不足している場合は追加する
3. 全テストがパスすることを確認

### Step 4: レビュー
1. 適切なサブエージェント（`rails-code-reviewer`, `rails-security-auditor`, `ansible-validator`等）でレビュー
2. `regression-checker` サブエージェントでデグレッションチェック
3. 指摘事項があれば自動で修正
4. 修正後、再度レビューを実行
5. 全ての指摘が解消されるまで 1-4 を繰り返す（最大3回）

### Step 5: Push & PR作成
1. **Step 1で読み込んだPRテンプレートの構成に従ってPRディスクリプションを作成する**（テンプレートがない場合は下記デフォルト構成を使用）
2. PRのQA手順を追記する
3. **PRディスクリプションを `/tmp/pr_description.md` に書き出す**
4. push を**自分で実行**する（main/develop への push は git フックで自動ブロックされる）
   - 初回: `git -C <repo_path> push -u origin <branch>`
   - 2回目以降: `git -C <repo_path> push`
   - **注意: `cd && git push` ではなく `git -C` 形式を使うこと**
5. `gh pr create` を**自分で実行**してPRを作成する
6. 作成したPRのURLをユーザーに報告する

### PRディスクリプションの構成（テンプレートがない場合）
```markdown
## 概要
（変更の目的・背景）

## 変更内容
（具体的な変更点）

## QA手順
（動作確認の手順）

## 影響範囲
（影響を受ける機能・画面）
```

**注意: PRディスクリプションは簡潔に記述すること。冗長な説明は避け、要点を端的にまとめる。**

## 4. Skills - 編集前に呼ぶ
**以下のファイルを編集する直前に、対応するSkillを必ず呼び出す：**

| File Pattern | Skill to Invoke |
|-------------|-----------------|
| `.rb`, `.py`, `.sql` | `backend-dev` |
| `Dockerfile`, `docker-compose*.yml`, `.ansible/`, `*.tf`, k8s manifests | `infra-quick-check` |
| ActiveRecord queries, raw SQL | `sql-helper` |

## 5. Agents - レビュー時に呼ぶ
**実装完了後、必ずサブエージェントでレビューを実施する：**
- Ansible変更 → `ansible-validator`, `infra-reviewer`
- Rails変更 → `rails-code-reviewer`, `rails-security-auditor`
- Go変更 → `go-code-reviewer`
- Shell/Bash変更 → `shell-script-reviewer`
- **全ての変更** → `regression-checker`（デグレッションチェック）

---

# Claude Code グローバル設定

## 基本設定
- コマンドを提示する際は、必ず一行で記述すること（コピーしやすくするため）。複数行に分割しない。
- 出力する文章やコードの冒頭・末尾に不要なスペースを入れないこと。

## 詳細ルール

### Skill詳細

#### backend-dev
- **対象ファイル**: `.rb`, `.py`, `.sql`
- **役割**: ベストプラクティス適用、N+1防止、簡単なバグ修正

#### infra-quick-check
- **対象ファイル**: `Dockerfile`, `docker-compose*.yml`, `.ansible/`配下, `*.tf`, k8s manifest
- **役割**: 構文チェック、基本的なセキュリティチェック

#### sql-helper
- **対象コード**: ActiveRecordクエリ、生SQLクエリ
- **役割**: N+1問題防止、インデックス提案、クエリ最適化

#### pr-review（ユーザー起動: `/pr-review`）
- **用途**: PRレビュー。`/pr-review <PR番号>` で起動
- **役割**: diffの取得→レビュー→GitHubにコメント投稿

#### investigate（ユーザー起動: `/investigate`）
- **用途**: コードベース調査。未使用コード検出、利用箇所調査、依存関係マッピング
- **役割**: Taskエージェントで並列調査し結果を集約

#### data-analysis（ユーザー起動: `/data-analysis`）
- **用途**: データ分析クエリ作成
- **役割**: スキーマ確認→サンプル検証→本番クエリの段階的フローで手戻り最小化

#### gcp-verify（ユーザー起動: `/gcp-verify`）
- **用途**: GCPインフラ検証
- **役割**: Cloud Run、IAM、Cloud Scheduler、ログシンク等の自動チェック

### Agent詳細

#### Ansibleファイルのレビュー（.ansible/roles/配下を変更した場合）
1. `ansible-validator` サブエージェントで構文・ベストプラクティスをチェック
2. `infra-reviewer` サブエージェントでセキュリティ・保守性をレビュー

#### Goファイルのレビュー（.goファイルを変更した場合）
1. `go-code-reviewer` サブエージェントでエラーハンドリング・並行処理・コード品質をチェック

#### シェルスクリプトのレビュー（.sh、Bashスクリプトを変更した場合）
1. `shell-script-reviewer` サブエージェントで安全性・移植性・ShellCheck対応をチェック

#### Railsファイルのレビュー（Railsプロジェクトを変更した場合）
1. **コード品質**: `rails-code-reviewer` サブエージェントでRails規約・アンチパターンをチェック
2. **セキュリティ**: `rails-security-auditor` サブエージェントで脆弱性を検出
3. **パフォーマンス** (必要に応じて): `rails-performance-optimizer` サブエージェントでN+1問題等を検出
4. **マイグレーション** (db/migrate/変更時): `rails-db-migration-reviewer` サブエージェントで安全性を確認
5. **テスト** (spec/変更時): `rails-test-guardian` サブエージェントでテストを実行

### カスタムスラッシュコマンド

#### /team - Agent Teams 協調作業モード（EXPERIMENTAL）
複雑なタスクを2人のエージェントチームで協調作業するモード。

**構成**:
- **Lead**: 計画立案 + 実装 + コミット担当
- **Reviewer**: 計画レビュー + 実装レビュー担当

**使い方**:
```
/team ユーザー認証機能にパスワードリセットを追加して
```

**ワークフロー**:
1. Lead が計画を立てる → Reviewer がレビュー
2. Lead が実装 → Reviewer がコードレビュー
3. Lead がコミット

**注意**:
- トークン消費が通常の2倍程度になる
- EXPERIMENTAL 機能（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` で有効化）
- 最小限のエージェントで試すことを推奨

#### /pr-review - PRレビュー
PR番号を指定してレビューを実行し、GitHubにコメントを投稿する。
```
/pr-review 1234
```

#### /investigate - コードベース調査
未使用コード、利用箇所、依存関係などを調査する。変更はしない。
```
/investigate SAML SSO機能の利用箇所を調べて
```

#### /data-analysis - データ分析
スキーマ確認→サンプル検証→本番クエリの段階的フローでデータ分析クエリを作成。
```
/data-analysis トーク機能のDAU推移を月別で出して
```

#### /gcp-verify - GCPインフラ検証
Cloud Run、IAM、Cloud Scheduler等の設定を自動チェックリストで検証。
```
/gcp-verify staging環境のCloud Run設定を確認
```

#### /sequential-thinking
Sequential thinking tool でタスクを深く分析する。

#### /plan
Plan Mode で複雑なタスクの実装計画を立てる。

### 効率化ルール
- コミットメッセージは変更内容から自動生成する
- 複数ファイルの読み込みや検索は並列で実行する

### テスト実行ルール
#### テストファイルを編集した場合
1. **即座にテストを実行する（ユーザーに依頼しない）**
2. テスト結果をユーザーに報告する
3. 失敗した場合は原因を調査し、修正する

#### 実装ファイルを編集した場合
1. **関連するテストを実行する（ユーザーに依頼しない）**
2. テスト結果をユーザーに報告する

### 変更の原則
- **コード変更は常に最小限のdiffを目指す。** リファクタリング、新クラス作成、過剰なテスト追加は明示的に依頼された場合のみ行う。1行で済む修正を複数ファイルの restructure にしない
- 変更前に影響範囲を調査し、既存テストの有無を確認
- プロジェクトのコーディング規約・ディレクトリ構造に従う

### ファイル削除時の確認ルール
ファイルを削除した場合、**必ず以下の関連箇所を確認・修正する**：
1. **インポート/require文** - 削除したファイルを参照しているコード
2. **設定ファイル** - ルーティング、設定、マニフェスト等での参照
3. **テストファイル** - 削除したファイルに対応するテスト
4. **ドキュメント** - README、CLAUDE.md等での言及

### ドキュメント更新の原則
- **プロジェクトCLAUDE.md**（リポジトリ直下やプロジェクトルート）はチーム全体に影響するため、**必ずユーザーに確認してから更新する**
- **グローバルCLAUDE.md**（~/.claude/CLAUDE.md）は個人設定なので自由に更新可能

### 環境固有の注意点
- macOS 環境では `sed` の代わりに `gsed`（GNU sed）がエイリアスされている場合がある。ファイル編集には `sed` コマンドではなく Edit ツールを使うこと
- git worktree で作業中、worktree が削除された場合はすぐにメインリポジトリのルートに `cd` して復帰する。削除済みディレクトリでコマンドを繰り返さない
- git worktree 内でのコミットは常に `--no-verify` を使用する（node_modules 等が不足しフックが失敗するため）

### 回答の正確性
- インフラ構成やコードベースに関する質問には、実際のコード・設定ファイル・コマンド出力で検証してから回答する。推測で答えない
- PRを番号で指定された場合は、コードベースを検索する前にまず `gh pr view` で直接確認する

### エラー対応
- エラーが発生したら即座に報告し、対処方法をユーザーと相談
- 繰り返し同じエラーで失敗する場合は、別のアプローチを提案
