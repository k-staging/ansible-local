---
name: gcp-verify
description: GCPインフラ設定を検証。Cloud Run、Cloud Scheduler、IAM、ログシンク等の設定を自動チェックリストで確認。
allowed-tools: Bash, Read, Grep
model: sonnet
user-invocable: true
---

# GCP Infrastructure Verification Skill

GCPリソースの設定を自動チェックリストで検証し、問題を検出します。

## 入力

ユーザーから以下を指定：
- 対象環境（staging / production）
- チェック対象（全体 or 特定カテゴリ）
- プロジェクトID（未指定なら `gcloud config get-value project` で取得）

## チェックカテゴリ

### 1. Cloud Run サービス
```bash
gcloud run services describe <service> --region <region> --format json
```
- 環境変数の設定漏れ
- インスタンス数（min/max）
- メモリ/CPU設定
- Ingress設定（internal / all）
- サービスアカウント

### 2. IAM バインディング
```bash
gcloud run services get-iam-policy <service> --region <region>
```
- Invoker権限の確認
- OIDC認証の設定
- 不要な権限の検出

### 3. Cloud Scheduler
```bash
gcloud scheduler jobs list --location <region>
```
- OIDC auth設定の確認
- ターゲットURLの正当性
- スケジュール（cron式）の確認

### 4. ログシンク / BigQuery
```bash
gcloud logging sinks list
```
- シンクのフィルタ条件
- BigQueryデータセットの存在確認
- 権限設定

### 5. 環境変数比較（GAE vs Cloud Run）
- 両サービスのenv varを取得して差分を出力

## 出力フォーマット

```markdown
## GCP検証結果: [環境名]

| カテゴリ | チェック項目 | 状態 | 備考 |
|---------|------------|------|------|
| Cloud Run | 環境変数 | OK / NG | 詳細 |
| IAM | Invoker権限 | OK / NG | 詳細 |
| ... | ... | ... | ... |

### 要対応
- [NG項目の修正コマンド]
```

## 重要ルール

- **実データで検証**: gcloudコマンドの出力を使い、推測で判断しない
- **修正コマンドを提示**: NGの場合は修正用のgcloudコマンドもセットで出す
- **環境を壊さない**: 検証は読み取りコマンドのみ。変更コマンドはユーザー確認後
