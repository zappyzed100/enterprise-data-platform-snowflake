# GOVERNANCE

このドキュメントは、Snowflake 上の権限モデル、managed access、削除保護の運用基準を定義します。

## 1. 目的

- 権限付与の責務を Terraform と bootstrap SQL に明確に分離する
- 本番環境の誤削除リスクを下げる
- functional role と data-layer access role を分離し、監査しやすい RBAC 階層を維持する

## 2. 適用範囲

- `terraform/modules/snowflake_env/` 配下の Snowflake role / user / warehouse / stage / table / grant 定義
- `terraform/bootstrap/sql/setup_snowflake_tf_dev.sql`
- `terraform/bootstrap/sql/setup_snowflake_tf_prod.sql`

## 3. 権限モデル

### 3.1 Functional Role

- Loader role: Bronze への取り込み実行主体
- dbt role: Bronze 読み取り、Silver/Gold 変換実行主体
- Streamlit role: Gold の参照主体

### 3.2 Data-layer Access Role

Terraform では、以下の access role を作成し functional role の下位に付与します。

- `<ENV>_BRONZE_LOADER_RW_ROLE`
- `<ENV>_BRONZE_TRANSFORM_RO_ROLE`
- `<ENV>_SILVER_TRANSFORM_RW_ROLE`
- `<ENV>_GOLD_PUBLISH_RW_ROLE`
- `<ENV>_GOLD_CONSUME_RO_ROLE`

原則:

- オブジェクト権限は access role に付与する
- アプリケーションやユーザーへは functional role を直接割り当てる
- functional role は warehouse 利用権限と access role の束ね役に限定する

## 4. Managed Access 方針

- Bronze / Silver / Gold の各 schema は managed access を有効化する
- schema owner は bootstrap で `<ENV>_TF_ADMIN_ROLE` に集約する
- grant の変更は Terraform から行い、手作業の grant 追加は原則禁止とする

補足:

- 既存 schema への適用は `ALTER SCHEMA ... ENABLE MANAGED ACCESS;` で行う
- managed access 適用後、オブジェクト所有者ではなく schema owner が grant を統制する

## 5. 削除保護

- すべての環境で以下を critical resource とみなし、`prevent_destroy = true` を適用する

対象:

- account role
- user
- warehouse
- bronze stage
- bronze raw tables
- file format

## 6. 変更管理

- 権限モデル変更は同一 PR で `docs/DECISIONS.md` と ADR を更新する
- managed access や `prevent_destroy` に影響する変更は PR 本文に rollback 方針を記載する
- データ契約に影響する変更は `docs/DATA_CONTRACT.md` も更新する

## 7. 検証観点

- Terraform lint/validate が通ること
- grant 変更後も loader/dbt/streamlit の責務分離が維持されること
- critical resource の destroy plan がブロックされること

## 8. 関連ドキュメント

- `CONTRIBUTING.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md`
- `docs/DATA_CONTRACT.md`
- `docs/DEPLOYMENT.md`
- `docs/TESTING.md`
- `terraform/README.md`