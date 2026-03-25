# Terraform 運用ガイド

このディレクトリでは HCP Terraform (remote backend) を利用します。

## 基本方針

- backend 設定は `backend.hcl` + `backend.<env>.hcl` で分離する
- workspace 切替時は `terraform init -reconfigure` を実行する
- 実行変数は HCP Terraform の Workspace Variables で管理する

Terraform backend 設定は通常の入力変数で動的切替できないため、環境ごとの backend ファイルを使っています。

## backend ファイルの作り方

### 1. 共通ファイル: `backend.hcl`

```hcl
# Git管理しない
organization = "<your-hcp-organization>"
```

### 2. DEV 用: `backend.dev.hcl`

```hcl
workspaces {
  name = "<dev-workspace-name>"
}
```

### 3. PROD 用: `backend.prod.hcl`

```hcl
workspaces {
  name = "<prod-workspace-name>"
}
```

## 実行手順

Docker イメージには Terraform CLI を同梱しています。
`docker compose up --build` 後のコンテナ内では、そのまま `terraform` を実行できます。

### 1. 事前準備

```bash
terraform login
cd terraform
```

### 2. DEV ワークスペース

```bash
terraform init -reconfigure -backend-config="backend.hcl" -backend-config="backend.dev.hcl"
terraform plan
terraform apply
```

### 3. PROD ワークスペース

```bash
terraform init -reconfigure -backend-config="backend.hcl" -backend-config="backend.prod.hcl"
terraform plan
terraform apply
```

## 変数管理

HCP Terraform はリモート実行のため、ローカル `.tfvars` は使いません。
Workspace の Variables 画面に登録してください。

- URL: `https://app.terraform.io/app/<org>/<workspace>/settings/vars`
- 種別: `Terraform variable`

| 変数名                         | Sensitive | 内容 (例)                                         |
|--------------------------------|-----------|---------------------------------------------------|
| snowflake_organization_name    | いいえ    | SNOWFLAKE_ACCOUNT の前半分                        |
| snowflake_account_name         | いいえ    | SNOWFLAKE_ACCOUNT の後半分                        |
| snowflake_user                 | いいえ    | TF_PROVISIONER (Terraform実行ユーザー)            |
| snowflake_private_key          | はい      | RSA秘密鍵 PEM 本文                                |
| dev_loader_user_rsa_public_key | はい      | LoaderユーザーのRSA公開鍵 PEM 本文                |
| dev_dbt_user_rsa_public_key    | はい      | dbtユーザーのRSA公開鍵 PEM 本文                   |

`snowflake_private_key` は入力時に改行が `\n` になっていても、コード側で改行復元して利用します。

## lifecycle.prevent_destroy を false にしている理由

`modules/snowflake_env/main.tf` の主要リソースで `prevent_destroy = false` を明示しています。

理由は次の通りです。

- 初期構築時に import/再作成の調整が必要になるケースがある
- 学習・検証フェーズで作っては壊すサイクルが発生する
- 既存リソースとの差分解消で destroy が必要になる場面がある

本番で保護を強める場合は、Database/Schema/Role/User から順に `true` へ戻す運用を推奨します。

## Network Policy をあえて設定しない理由

`modules/snowflake_env/main.tf` 末尾の Network Policy はサンプルとしてコメントアウトしています。

現時点で適用しない理由は次の通りです。

- 実行環境（HCP Terraform 実行元IP）が固定ではなく、固定CIDR前提だと接続断が起きやすい
- 開発段階ではまずデータ基盤リソースの安定化を優先したい
- 誤ったIP制限は管理者自身のロックアウトにつながる

Network Policy を導入する場合は、実行元IPを設計で確定させてから別PRで段階導入する方針とします。

