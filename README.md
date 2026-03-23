# Enterprise Data Platform with Snowflake & dbt

配送コスト最適化ロジックを **Snowpark Python UDF** として実装し、**dbt** によるメダリオン・アーキテクチャで管理・自動化したエンドツーエンドのデータパイプラインです。

---

## 🚀 プロジェクトのハイライト
* **dbt x Snowflake Architecture**: Bronze/Silver/Gold の 3 層構造によるデータガバナンスの実現。
* **Hybrid Logic Execution**: SQL による高速な変換と、Python (Snowpark) による高度な配送コスト演算（ハバースサイン公式）を dbt モデル内で統合。
* **Automated Data Quality**: dbt tests による整合性チェックと、GitHub Actions による CI パイプライン。
* **Modern Toolstack**: `uv` による高速な依存関係管理と、Snowflake 接続情報の Secrets 管理の徹底。

---

## 🏗 アーキテクチャ

1.  **Ingestion (Bronze)**: Faker で生成した 10,000 件の擬似データをロード。
2.  **Transformation (Silver)**: `stg_orders` 等のモデルで型定義とクレンジングを実施。
3.  **Optimization (Gold)**: `fct_delivery_analysis` において、Python UDF を呼び出し、最短配送拠点を自動選択（`QUALIFY` 句）。
4.  **CI/CD**: PR 時に自動で環境構築・構文チェック・データテストを実行。

---

## 📊 パイプライン品質 (Current Status)

dbt による変換モデルと GitHub Actions による CI を組み合わせ、データ品質と再現性を担保しています。

| 指標 | 結果 | 備考 |
| :--- | :--- | :--- |
| **dbt run 実行時間** | **~15s** | モデル構築・UDF 呼び出し・最短配送拠点抽出を含む |
| **データ品質テスト** | **PASS (10/10)** | unique, not_null, relationships 等 |
| **CI** | **PASS** | flake8, pytest, dbt debug, dbt test を自動実行 |

## ⚡ 計算ベンチマーク

10,000 件の注文データと 2 拠点の組み合わせ（20,000 レコード）に対し、配送コスト計算の実行速度を比較しました。

| 実装手法 | 実行時間 | スループット | 技術的考察 |
| :--- | :--- | :--- | :--- |
| **Pure SQL** | **705 ms** | **~28,368 rec/sec** | Snowflake の SQL エンジンで完結するため最速。 |
| **Python UDF** | **4.16 s** | **~4,804 rec/sec** | Pandas ベースで可読性・保守性が高い。 |

**分析:**
Pure SQL は最速ですが、Python UDF でも 20,000 レコードを数秒で処理できており、複雑なビジネスロジックを Python でテスト可能な形で実装できる点に価値があります。本プロジェクトでは、速度だけでなく保守性と拡張性も重視しています。

---

## 🛠 技術スタック
* **Data Warehouse**: Snowflake
* **Data Modeling**: dbt-core 1.11 (Snowflake adapter)
* **Compute Engine**: Snowpark for Python
* **Package Manager**: `uv` (Astral)
* **CI/CD**: GitHub Actions
* **Language**: SQL, Python 3.11

---

## 📂 ディレクトリ構造
```text
.
├── .github/workflows/      # CI (GitHub Actions) 設定
├── benchmark/
│   └── sql/                # Pure SQL ベンチマーク用クエリ
├── data/                   # サンプルCSVデータ(Git非推奨)
├── ddl/                    # Snowflakeテーブル定義
├── enterprise_data_pipeline/
│   ├── models/
│   │   ├── staging/        # Silver Layer (クレンジング・正規化)
│   │   └── marts/          # Gold Layer (UDF連携・最短拠点計算)
│   ├── target/             # dbt artifacts (dbt docs generate で一時生成。Git非推奨)
│   └── profiles.yml        # 環境変数参照によるセキュアな接続設定
├── src/
│   ├── scripts/            # データ生成・初期ロード・性能計測スクリプト
│   └── udf/                # 配送コスト計算ロジック
├── tests/                  # pytest と検証用SQL
└── README.md
```

---

## 📅 今後のロードマップ
- [ ] Streamlit による可視化: 分析マートの結果を地図上にプロットするシミュレーター。

- [ ] Incremental Models: 大規模ログデータの増分更新（100万行〜）の最適化。

- [ ] Data Security: 行レベルセキュリティ (RLS) による権限管理の実装。

---

## インフラ実行手順

Terraform / HCP Workspace の運用手順は [terraform/README.md](terraform/README.md) を参照してください。