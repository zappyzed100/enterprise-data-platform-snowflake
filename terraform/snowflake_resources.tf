# ロールとユーザーの定義
# --- loader ---
resource "snowflake_account_role" "snowflake_grant_account_role" {
  name    = "snowflake_grant_account_role"
}

resource "snowflake_user" "dev_loader_user" {
  name         = "DEV_LOADER_USER"
  login_name   = "DEV_LOADER_USER"
  password     = var.dev_loader_user_password # 環境変数等から注入
  default_role = upper(snowflake_account_role.snowflake_grant_account_role.name)
}

resource "snowflake_grant_account_role" "dev_loader_grants" {
  role_name = snowflake_account_role.snowflake_grant_account_role.name
  user_name = snowflake_user.dev_loader_user.name
}

# --- dbt ---
resource "snowflake_account_role" "dev_dbt_role" {
  name    = "DEV_DBT_ROLE"
}

resource "snowflake_user" "dbt_user" {
  name         = "DEV_DBT_USER"
  login_name   = "DEV_DBT_USER"
  password     = var.dev_dbt_user_password # 環境変数等から注入
  default_role = upper(snowflake_account_role.dev_dbt_role.name)
}

resource "snowflake_grant_account_role" "dbt_grants" {
  role_name = snowflake_account_role.dev_dbt_role.name
  user_name = snowflake_user.dbt_user.name
}

# 各処理専用のウェアハウス作成
# --- loader ---
resource "snowflake_warehouse" "dev_loader_wh" {
  name                = "DEV_LOADER_WH"
  warehouse_size      = "X-SMALL"     # 最小サイズ（コスト最適化）
  auto_suspend        = 60            # 60秒間クエリがないと自動停止（節約）
  auto_resume         = true          # クエリが来たら自動で再起動
  initially_suspended = true          # 作成直後は停止状態にする
}
# --- dbt ---
resource "snowflake_warehouse" "dev_dbt_wh" {
  name                = "DEV_DBT_WH"
  warehouse_size      = "X-SMALL"     # 最小サイズ（コスト最適化）
  auto_suspend        = 60            # 60秒間クエリがないと自動停止（節約）
  auto_resume         = true          # クエリが来たら自動で再起動
  initially_suspended = true          # 作成直後は停止状態にする
}

# データベース・スキーマの定義
# --- Bronze Layer (生データ) ---
resource "snowflake_database" "dev_bronze" {
  name = "DEV_BRONZE_DB"
}

resource "snowflake_schema" "dev_bronze_raw" {
  database = snowflake_database.dev_bronze.name
  name     = "RAW_DATA" # 外部から取り込んだそのままのデータが入る場所
}

# --- Silver Layer (中間加工) ---
resource "snowflake_database" "dev_silver" {
  name = "DEV_SILVER_DB"
}

resource "snowflake_schema" "dev_silver_cleansed" {
  database = snowflake_database.dev_silver.name
  name     = "CLEANSED" # 型変換やクレンジング後のデータ
}

# --- Gold Layer (展示層) ---
resource "snowflake_database" "dev_gold" {
  name = "DEV_GOLD_DB"
}

resource "snowflake_schema" "dev_gold_mart" {
  database = snowflake_database.dev_gold.name
  name     = "MARKETING_MART"
}

# 内部ステージ（PUTコマンドの宛先）
resource "snowflake_stage_internal" "dev_bronze_raw_stage" {
  name     = "dev_bronze_raw_STAGE"
  database = snowflake_database.dev_bronze.name
  schema   = snowflake_schema.dev_bronze_raw.name
}

# データの受け皿となるテーブル (Bronze/RAWレイヤー)
resource "snowflake_table" "dev_orders" {
  database = snowflake_database.dev_bronze.name
  schema   = snowflake_schema.dev_bronze_raw.name
  name     = "ORDERS"

  # ID類も一旦 STRING で受けることで、予期せぬ文字列混入による停止を防ぐ
  column {
    name     = "ORDER_ID"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "PRODUCT_ID"
    type     = "STRING"
    nullable = true
  }

  # 数値型も、一旦 STRING で受けて Silver で CAST するのが最も堅牢
  column {
    name     = "QUANTITY"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "CUSTOMER_LAT"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "CUSTOMER_LON"
    type     = "STRING"
    nullable = true
  }

  # 日付もフォーマット違いを許容するために STRING またはデフォルト値なし
  column {
    name     = "ORDER_DATE"
    type     = "STRING"
    nullable = true
  }

  # --- Metadata Columns ---
  column {
    name = "SOURCE_FILE"
    type = "STRING"
    comment = "取り込み元のファイル名"
  }

  # 取り込み日時（メタデータ）を追加：いつ届いたデータか判別するため
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "dev_inventory" {
  database = snowflake_database.dev_bronze.name
  schema   = snowflake_schema.dev_bronze_raw.name
  name     = "INVENTORY"

  column {
    name     = "CENTER_ID"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "PRODUCT_ID"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "STOCK_QUANTITY"
    type     = "STRING"
    nullable = true
  }

  # --- Metadata Columns ---
  column {
    name = "SOURCE_FILE"
    type = "STRING"
    comment = "取り込み元のファイル名"
  }

  # 取り込み日時（メタデータ）を追加：いつ届いたデータか判別するため
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "dev_logistics_centers" {
  database = snowflake_database.dev_bronze.name
  schema   = snowflake_schema.dev_bronze_raw.name
  name     = "LOGISTICS_CENTERS"

  column {
    name     = "CENTER_ID"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "CENTER_NAME"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "LATITUDE"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "LONGITUDE"
    type     = "STRING"
    nullable = true
  }

  # --- Metadata Columns ---
  column {
    name = "SOURCE_FILE"
    type = "STRING"
    comment = "取り込み元のファイル名"
  }

  # 取り込み日時（メタデータ）を追加：いつ届いたデータか判別するため
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "dev_products" {
  database = snowflake_database.dev_bronze.name
  schema   = snowflake_schema.dev_bronze_raw.name
  name     = "PRODUCTS"

  column {
    name     = "PRODUCT_ID"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "PRODUCT_NAME"
    type     = "STRING" 
    nullable = true
  }

  column {
    name     = "CATEGORY"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "WEIGHT_KG"
    type     = "STRING"
    nullable = true
  }

  column {
    name     = "UNIT_PRICE"
    type     = "STRING"
    nullable = true
  }

  # --- Metadata Columns ---
  column {
    name = "SOURCE_FILE"
    type = "STRING"
    comment = "取り込み元のファイル名"
  }

  # 取り込み日時（メタデータ）を追加：いつ届いたデータか判別するため
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

# File Format
resource "snowflake_file_format" "dev_csv_format" {
  name        = "DEV_CSV_FORMAT"
  database    = snowflake_database.dev_bronze.name
  schema      = snowflake_schema.dev_bronze_raw.name
  format_type = "CSV"
  
  field_delimiter  = ","
  skip_header      = 1
  trim_space = true
  field_optionally_enclosed_by = "\"" # 囲み文字がある場合
  null_if          = ["NULL", ""]
}

# 権限付与
# --- loader ---
# ------ warehouse ------
resource "snowflake_grant_privileges_to_account_role" "dev_loader_wh_usage" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dev_loader_wh.name
  }
}

# ------ bronze ------
resource "snowflake_grant_privileges_to_account_role" "dev_loader_bronze_usage" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = snowflake_database.dev_bronze.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_loader_raw_usage" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_loader_stage_read_write" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["READ", "WRITE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_stage_internal.dev_bronze_raw_stage.name}"
  }
}

# ------ table ------
resource "snowflake_grant_privileges_to_account_role" "dev_order_table_insert" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_table.dev_orders.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_inventory_table_insert" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_table.dev_inventory.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_logistics_centers_table_insert" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_table.dev_logistics_centers.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_order_products_insert" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_table.dev_products.name}"
  }
}
# ------ File Format ------
resource "snowflake_grant_privileges_to_account_role" "dev_loader_ff_usage" {
  account_role_name = snowflake_account_role.snowflake_grant_account_role.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}.${snowflake_file_format.dev_csv_format.name}"
  }
}

# --- dbt ---

# ------ warehouse ------
resource "snowflake_grant_privileges_to_account_role" "dev_dbt_wh_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dev_dbt_wh.name
  }
}

# --- bronze ---
resource "snowflake_grant_privileges_to_account_role" "dev_dbt_bronze_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = snowflake_database.dev_bronze.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_bronze_raw_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_bronze_select" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_bronze_select_future" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_bronze.name}.${snowflake_schema.dev_bronze_raw.name}"
    }
  }
}

# ------ silver ------

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_silver_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = snowflake_database.dev_silver.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_cleansed_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  all_privileges    = true

  on_schema {
    schema_name = "${snowflake_database.dev_silver.name}.${snowflake_schema.dev_silver_cleansed.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_gold_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = snowflake_database.dev_gold.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_dbt_mart_usage" {
  account_role_name = snowflake_account_role.dev_dbt_role.name
  all_privileges    = true

  on_schema {
    schema_name = "${snowflake_database.dev_gold.name}.${snowflake_schema.dev_gold_mart.name}"
  }
}

