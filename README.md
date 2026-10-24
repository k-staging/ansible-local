# このリポジトリについて
mac, wsl のローカル環境構築を行う為の ansible です。
詳細な使い方については [mac/README.md](mac/README.md) または [wsl/README.md](wsl/README.md) を参照ください。

## カスタムスラッシュコマンド

このリポジトリでは、Claude Code のカスタムスラッシュコマンドを提供しています。

### /team - Agent Teams 協調作業モード（EXPERIMENTAL）

2人のエージェントチーム（Lead + Reviewer）で協調作業を行うモード。

**使い方**:
```
/team <タスク内容>
```

**例**:
```
/team ユーザー認証機能にパスワードリセットを追加して
```

**チーム構成**:
- **Lead**: 計画立案 + 実装 + コミット担当
- **Reviewer**: 計画レビュー + 実装レビュー担当

**注意**:
- EXPERIMENTAL 機能のため、今後の Claude Code アップデートで動作が変わる可能性があります
- トークン消費が通常の2倍程度になります
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` で有効化しています

### その他のコマンド

- `/sequential-thinking` - Sequential thinking tool でタスクを深く分析
- `/plan` - Plan Mode で複雑なタスクの実装計画を立てる

