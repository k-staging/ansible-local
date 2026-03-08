---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/docker-compose*.yml"
  - "**/*.tf"
  - "**/k8s/**/*.yml"
  - "**/kubernetes/**/*.yml"
---
# インフラ設定ルール

## 編集前
- `infra-quick-check` Skill を呼び出すこと

## Dockerfile
- マルチステージビルドを活用し、イメージサイズを最小化
- `latest` タグは使わず、バージョンを固定する
- 非rootユーザーで実行する

## Terraform
- `terraform fmt` 準拠のフォーマットにする
- リソース名はスネークケースで統一
