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
