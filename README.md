# Enterprise Data Platform with Snowflake and dbt

このリポジトリは、配送データを Snowflake に取り込み、dbt で Bronze/Silver/Gold に変換し、最終結果を Streamlit で可視化するプロジェクトです。

## 最初に読む場所

- dbt の詳細: enterprise_data_pipeline/README.md
- src の運用詳細: src/README.md
- Terraform/HCP の詳細: terraform/README.md

## 何ができるか

1. 受注データと在庫データを生成する
2. Snowflake Bronze にロードする
3. dbt で Silver/Gold モデルを作成する
4. Gold モデルを Streamlit で可視化する

## クイックスタート (初回 15 分)

以下は「何もない状態から動かす」最短手順です。

### 1) 依存関係をインストール

```bash
uv sync
```

### 2) 接続情報を設定

2 種類の設定が必要です。

1. dbt / loader 用の環境変数 (`.env`)
2. Streamlit 用の secrets (`.streamlit/secrets.toml`)

`.env` 最小例。

```dotenv
SNOWFLAKE_ACCOUNT=your-account
DEV_DBT_USER_RSA_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
SNOWFLAKE_LOADER_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

`.streamlit/secrets.toml` 最小例。

```toml
[connections.snowpark]
account = "your-account"
user = "your-user"
password = "your-password"
role = "DEV_DBT_ROLE"
warehouse = "DEV_DBT_WH"
database = "DEV_GOLD_DB"
schema = "MARKETING_MART"
```

注意。

- Streamlit アプリは `.env` ではなく `st.secrets["connections"]["snowpark"]` を参照します。
- `.streamlit/secrets.toml` がないと起動時にエラーになります。

### 3) データを生成

```bash
uv run python src/scripts/data_gen/generate_large_data.py -n 10000
```

### 4) Snowflake Bronze にロード

```bash
uv run python src/infrastructure/snowflake_loader.py
```

### 5) dbt モデルを作成

dbt は必ずラッパー経由で実行します。

```bash
uv run python src/scripts/deploy/run_dbt.py debug
uv run python src/scripts/deploy/run_dbt.py run --select +int_delivery_cost_candidates +fct_delivery_analysis
uv run python src/scripts/deploy/run_dbt.py test
```

### 6) Streamlit を起動

```bash
uv run streamlit run src/streamlit/app.py
```

## Terraform で Snowflake リソースを適用する

Snowflake のロール/DB/ユーザーなどの基盤リソースは `terraform/` で管理します。
詳細な設計方針は `terraform/README.md` を参照してください。ここでは最短手順のみ記載します。

Docker イメージには Terraform CLI を同梱しています（`docker compose up --build` 後のコンテナ内で利用可）。

### 1) 事前準備

```bash
terraform login
cd terraform
```

### 2) DEV へ適用

```bash
terraform init -reconfigure -backend-config="backend.hcl" -backend-config="backend.dev.hcl"
terraform plan
terraform apply
```

### 3) PROD へ適用

```bash
terraform init -reconfigure -backend-config="backend.hcl" -backend-config="backend.prod.hcl"
terraform plan
terraform apply
```

### 4) 補足

- HCP Terraform の remote backend 前提です
- 実行変数はローカル `.tfvars` ではなく、HCP Terraform Workspace Variables に設定します
- ワークスペースを切り替えるたびに `terraform init -reconfigure` を実行します

## Docker で開発する

このプロジェクトは Snowflake を外部データ基盤として利用します。
そのため、Docker Compose の目的は「アプリ実行環境の統一」であり、ローカルDBコンテナの同梱ではありません。

### 1) 事前準備

1. `.env` を作成し、Snowflake 接続用の環境変数を設定する
2. `.streamlit/secrets.toml` を作成する

最小例は上記「クイックスタート」の設定例を参照してください。

### 2) ビルドと起動

Streamlit を起動します。

```bash
docker compose up --build
```

API も起動する場合。

```bash
docker compose --profile api up --build
```

Dagster も起動する場合。

```bash
docker compose --profile orchestration up --build
```

### 3) 動作確認

1. 起動状態の確認

```bash
docker compose ps
```

2. ホストからのアクセス確認
- Streamlit: `http://localhost:8501`
- FastAPI (profile api 起動時): `http://localhost:8000/docs`
- Dagster (profile orchestration 起動時): `http://localhost:3000`

3. ホットリロード確認
- ホスト側で `src/streamlit/app.py` または `src/api/main.py` を編集し、画面/レスポンスに変更が反映されること

4. Snowflake 接続確認
- アプリ起動後、接続エラーが発生しないこと
- 必要に応じて以下で dbt 接続確認を実施する

```bash
docker compose run --rm streamlit python src/scripts/deploy/run_dbt.py debug
```

### 4) 停止

```bash
docker compose down
```

## Docker 導入Issueの完了チェック

- [ ] `docker compose up --build` で対象サービスが起動する
- [ ] ホストから Streamlit/API へアクセスできる
- [ ] コード変更がコンテナ実行へ反映される（ホットリロード）
- [ ] Snowflake 接続確認ができる
- [ ] 本 README の Docker 手順で再現できる

## 現在の実装方針

- 配送コスト計算は dbt の Pure SQL モデルを主軸にしています
- Python UDF 関連コードは一部レガシー検証用途として残っています
- CI は flake8 と pytest を実行します

## ディレクトリ要点

```text
.
├── enterprise_data_pipeline/  # dbt project
├── src/
│   ├── infrastructure/        # Bronzeロード
│   ├── scripts/               # データ生成、dbt実行補助
│   └── streamlit/             # 可視化アプリ
├── benchmark/sql/             # SQLベンチマーク
├── data/                      # 生成データ
└── terraform/                 # Snowflakeリソース管理
```

## よくある詰まりどころ

1. dbt が接続できない
- `.env` の鍵設定とロールを確認
- `run_dbt.py` 経由で実行しているか確認

2. Streamlit が起動時に失敗する
- `.streamlit/secrets.toml` が存在するか確認
- `connections.snowpark` のキー名ミスを確認

3. dbt run で権限エラーになる
- Terraform の権限適用 (`terraform apply`) を確認
