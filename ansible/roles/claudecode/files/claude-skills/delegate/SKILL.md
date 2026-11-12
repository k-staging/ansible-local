---
name: delegate
description: 会話で決まった作業を Issue にし、Issue を自動実装するルーティンに引き渡す。/delegate <作業内容> で使用。
allowed-tools: Read, Write, Grep, Glob, Bash, RemoteTrigger
user-invocable: true
---

# Delegate Skill

会話で決まった作業を、それだけ読めば着手できる Issue にまとめ、`claude-ready` ラベルを付けて作成します。Issue は、`claude-ready` の付いた Issue を実装して PR を作るルーティン（`/schedule` で作成したもの）が処理します。

## 入力

ユーザーから以下のいずれかで指定される：
- 作業内容（例: `/delegate tmux のキーバインドを追加`）
- 「これ別でやっといて」など、直前までの会話で決まった作業を指す依頼

## 実行フロー

### 1. 対象リポジトリの確認
```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
```
- 作業内容が別のリポジトリに関するものなら、Issue を作る前にユーザーに確認する

### 2. Issue 本文の作成
会話の内容と、必要ならコードを読んで、以下の構成で書く（**簡潔に、要点のみ**）：

```markdown
## 背景
（なぜこの作業が必要か）

## やること
（具体的な変更内容。箇条書き）

## 対象ファイル
- `path/to/file` - 変更内容

## 完了条件
（何ができたら完了か。確認方法も書く）

## 注意事項
（守ってほしいルール・やってはいけないこと。なければ省略）
```

- **実装するセッションには、この会話もローカルの `~/.claude/CLAUDE.md` も渡らない**。会話で決めた方針・前提・却下した案は、本文に書く
- 対象ファイルは実在を確認してからパスを書く
- 1 Issue 1 目的にする。複数の作業があれば Issue を分ける

### 3. ユーザー確認
タイトルと本文をユーザーに見せて承認をもらう。承認をもらうまで Issue を作成しない。

### 4. Issue の作成
1. `claude-ready` ラベルの有無を確認する（ラベルがなければ、作成してよいかユーザーに確認する）
   ```bash
   gh label list --search claude-ready --json name --jq '.[].name'
   ```
2. `echo "$TMPDIR"` で実際のパスを確認し、そのパスの `delegate_issue_<リポジトリ名>.md` に Write で本文を書き出す。Read で中身を確認してから作成する
   ```bash
   gh issue create --title "<タイトル>" --body-file "<確認したパス>/delegate_issue_<リポジトリ名>.md" --label claude-ready
   ```
3. 作成した Issue の URL をユーザーに報告する

### 5. ルーティンの即時実行（ユーザーが「今すぐ」と言った場合のみ）
1. `RemoteTrigger` の `list` で、プロンプトに `claude-ready` と対象リポジトリ名を含むルーティンを探す（ID は決め打ちしない）
2. 見つかったら、名前と次回実行時刻をユーザーに伝えたうえで `run` で実行する。結果の claude.ai の URL を報告する
3. 見つからない、または複数見つかった場合は実行せず、その旨を報告する

## 重要ルール

- **承認前に Issue を作らない**: 本文は必ずユーザーに見せてから作成する
- **Issue だけで完結させる**: 「会話のとおり」「上記の件」など、会話を前提にした書き方をしない
- **秘密情報を書かない**: トークン・パスワード・個人の絶対パスを本文に入れない
- **頼まれていない即時実行はしない**: ルーティンの `run` は、ユーザーが「今すぐ」と言ったときだけ行う
