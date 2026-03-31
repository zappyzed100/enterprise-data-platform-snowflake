locals {
  env                           = upper(var.env)
  bronze_db_name                = var.bronze_db_name
  silver_db_name                = var.silver_db_name
  gold_db_name                  = var.gold_db_name
  bronze_schema_name            = var.bronze_schema_name
  silver_schema_name            = var.silver_schema_name
  gold_schema_name              = var.gold_schema_name
  read_only_role_name           = "${local.env}_READ_ONLY_ROLE"
  read_write_role_name          = "${local.env}_READ_WRITE_ROLE"
  bronze_loader_rw_role_name    = "${local.env}_BRONZE_LOADER_RW_ROLE"
  bronze_transform_ro_role_name = "${local.env}_BRONZE_TRANSFORM_RO_ROLE"
  silver_transform_rw_role_name = "${local.env}_SILVER_TRANSFORM_RW_ROLE"
  gold_publish_rw_role_name     = "${local.env}_GOLD_PUBLISH_RW_ROLE"
  gold_consume_ro_role_name     = "${local.env}_GOLD_CONSUME_RO_ROLE"
}

# ============================================================
# Roles & Users
# ============================================================

# --- Loader ---
resource "snowflake_account_role" "loader_role" {
  name = var.loader_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_user" "loader_user" {
  name           = var.loader_user_name
  login_name     = var.loader_user_name
  rsa_public_key = var.loader_user_rsa_public_key
  default_role   = snowflake_account_role.loader_role.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_grant_account_role" "loader_role_grant" {
  role_name = snowflake_account_role.loader_role.name
  user_name = snowflake_user.loader_user.name
}

# --- dbt ---
resource "snowflake_account_role" "dbt_role" {
  name = var.dbt_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_user" "dbt_user" {
  name           = var.dbt_user_name
  login_name     = var.dbt_user_name
  rsa_public_key = var.dbt_user_rsa_public_key
  default_role   = snowflake_account_role.dbt_role.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_grant_account_role" "dbt_role_grant" {
  role_name = snowflake_account_role.dbt_role.name
  user_name = snowflake_user.dbt_user.name
}

# --- Streamlit Reader ---

resource "snowflake_account_role" "streamlit_role" {
  name = var.streamlit_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_user" "streamlit_user" {
  name       = var.streamlit_user_name
  login_name = var.streamlit_user_name
  # 必要に応じてパスワード認証またはキーペア認証を選択
  rsa_public_key = var.streamlit_user_rsa_public_key
  default_role   = snowflake_account_role.streamlit_role.name
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_grant_account_role" "streamlit_role_grant" {
  role_name = snowflake_account_role.streamlit_role.name
  user_name = snowflake_user.streamlit_user.name
}

# --- Shared policy roles ---
resource "snowflake_account_role" "read_only_role" {
  name = local.read_only_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_account_role" "read_write_role" {
  name = local.read_write_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_grant_account_role" "read_only_to_streamlit_role" {
  role_name        = snowflake_account_role.read_only_role.name
  parent_role_name = snowflake_account_role.streamlit_role.name
}

resource "snowflake_grant_account_role" "read_write_to_loader_role" {
  role_name        = snowflake_account_role.read_write_role.name
  parent_role_name = snowflake_account_role.loader_role.name
}

resource "snowflake_grant_account_role" "read_write_to_dbt_role" {
  role_name        = snowflake_account_role.read_write_role.name
  parent_role_name = snowflake_account_role.dbt_role.name
}

resource "snowflake_grant_account_role" "read_only_to_read_write_role" {
  role_name        = snowflake_account_role.read_only_role.name
  parent_role_name = snowflake_account_role.read_write_role.name
}

# --- Shared access roles ---
resource "snowflake_account_role" "bronze_loader_rw_role" {
  name = local.bronze_loader_rw_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_account_role" "bronze_transform_ro_role" {
  name = local.bronze_transform_ro_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_account_role" "silver_transform_rw_role" {
  name = local.silver_transform_rw_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_account_role" "gold_publish_rw_role" {
  name = local.gold_publish_rw_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_account_role" "gold_consume_ro_role" {
  name = local.gold_consume_ro_role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_grant_account_role" "bronze_loader_rw_to_loader_role" {
  role_name        = snowflake_account_role.bronze_loader_rw_role.name
  parent_role_name = snowflake_account_role.read_write_role.name
}

resource "snowflake_grant_account_role" "bronze_transform_ro_to_dbt_role" {
  role_name        = snowflake_account_role.bronze_transform_ro_role.name
  parent_role_name = snowflake_account_role.read_only_role.name
}

resource "snowflake_grant_account_role" "silver_transform_rw_to_dbt_role" {
  role_name        = snowflake_account_role.silver_transform_rw_role.name
  parent_role_name = snowflake_account_role.read_write_role.name
}

resource "snowflake_grant_account_role" "gold_publish_rw_to_dbt_role" {
  role_name        = snowflake_account_role.gold_publish_rw_role.name
  parent_role_name = snowflake_account_role.read_write_role.name
}

resource "snowflake_grant_account_role" "gold_consume_ro_to_streamlit_role" {
  role_name        = snowflake_account_role.gold_consume_ro_role.name
  parent_role_name = snowflake_account_role.read_only_role.name
}

# ============================================================
# Warehouses
# ============================================================

resource "snowflake_warehouse" "loader_wh" {
  name                = var.loader_warehouse_name
  warehouse_size      = "X-SMALL" # 最小サイズ（コスト最適化）
  auto_suspend        = 60        # 60秒間クエリがないと自動停止
  auto_resume         = true      # クエリが来たら自動で再起動
  initially_suspended = true      # 作成直後は停止状態にする

  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_warehouse" "dbt_wh" {
  name                = var.dbt_warehouse_name
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_warehouse" "streamlit_wh" {
  name                = var.streamlit_warehouse_name
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# Stage
# ============================================================

# 内部ステージ（PUTコマンドの宛先）
resource "snowflake_stage_internal" "bronze_raw_stage" {
  name     = var.bronze_stage_name
  database = local.bronze_db_name
  schema   = local.bronze_schema_name

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# Tables (Bronze / RAW Layer)
# ============================================================

resource "snowflake_table" "orders" {
  database = local.bronze_db_name
  schema   = local.bronze_schema_name
  name     = "ORDERS"

  lifecycle {
    prevent_destroy = true
  }

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
  # 日付もフォーマット違いを許容するために STRING
  column {
    name     = "ORDER_DATE"
    type     = "STRING"
    nullable = true
  }
  column {
    name    = "SOURCE_FILE"
    type    = "STRING"
    comment = "取り込み元のファイル名"
  }
  # 取り込み日時（メタデータ）：いつ届いたデータか判別するため
  column {
    name = "LOADED_AT"
    type = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "inventory" {
  database = local.bronze_db_name
  schema   = local.bronze_schema_name
  name     = "INVENTORY"

  lifecycle {
    prevent_destroy = true
  }

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
  column {
    name    = "SOURCE_FILE"
    type    = "STRING"
    comment = "取り込み元のファイル名"
  }
  column {
    name = "LOADED_AT"
    type = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "logistics_centers" {
  database = local.bronze_db_name
  schema   = local.bronze_schema_name
  name     = "LOGISTICS_CENTERS"

  lifecycle {
    prevent_destroy = true
  }

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
  column {
    name    = "SOURCE_FILE"
    type    = "STRING"
    comment = "取り込み元のファイル名"
  }
  column {
    name = "LOADED_AT"
    type = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_table" "products" {
  database = local.bronze_db_name
  schema   = local.bronze_schema_name
  name     = "PRODUCTS"

  lifecycle {
    prevent_destroy = true
  }

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
  column {
    name    = "SOURCE_FILE"
    type    = "STRING"
    comment = "取り込み元のファイル名"
  }
  column {
    name = "LOADED_AT"
    type = "TIMESTAMP_NTZ"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

# ============================================================
# File Format
# ============================================================

resource "snowflake_file_format" "csv_format" {
  name        = var.loader_file_format_name
  database    = local.bronze_db_name
  schema      = local.bronze_schema_name
  format_type = "CSV"

  lifecycle {
    prevent_destroy = true
  }

  field_delimiter              = ","
  skip_header                  = 1
  trim_space                   = true
  field_optionally_enclosed_by = "\"" # 囲み文字がある場合
  null_if                      = ["NULL", ""]
}

# ============================================================
# Grants — Loader Role
# ============================================================

# ------ warehouse ------
resource "snowflake_grant_privileges_to_account_role" "loader_wh_usage" {
  account_role_name = snowflake_account_role.loader_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.loader_wh.name
  }
}

# ------ bronze ------
resource "snowflake_grant_privileges_to_account_role" "loader_bronze_db_usage" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = local.bronze_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_bronze_usage" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = local.bronze_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_raw_schema_usage" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${local.bronze_db_name}.${local.bronze_schema_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_stage_read_write" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["READ", "WRITE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_stage_internal.bronze_raw_stage.name}"
  }
}

# ------ tables ------
resource "snowflake_grant_privileges_to_account_role" "loader_orders_insert" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_table.orders.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_inventory_insert" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_table.inventory.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_logistics_insert" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_table.logistics_centers.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_products_insert" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["INSERT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_table.products.name}"
  }
}

# ------ file format ------
resource "snowflake_grant_privileges_to_account_role" "loader_ff_usage" {
  account_role_name = snowflake_account_role.bronze_loader_rw_role.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "${local.bronze_db_name}.${local.bronze_schema_name}.${snowflake_file_format.csv_format.name}"
  }
}

# ============================================================
# Grants — dbt Role
# ============================================================

# ------ warehouse ------
resource "snowflake_grant_privileges_to_account_role" "dbt_wh_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt_wh.name
  }
}

# ------ bronze ------
resource "snowflake_grant_privileges_to_account_role" "dbt_bronze_db_usage" {
  account_role_name = snowflake_account_role.bronze_transform_ro_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = local.bronze_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_bronze_usage" {
  account_role_name = snowflake_account_role.bronze_transform_ro_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = local.bronze_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_bronze_raw_usage" {
  account_role_name = snowflake_account_role.bronze_transform_ro_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${local.bronze_db_name}.${local.bronze_schema_name}"
  }
}

module "dbt_bronze_table_grants" {
  source = "./modules/schema_object_grants"

  account_role_name  = snowflake_account_role.bronze_transform_ro_role.name
  in_schema          = "${local.bronze_db_name}.${local.bronze_schema_name}"
  object_type_plural = "TABLES"
  permission_level   = "SELECT"
  grant_on_all       = true
  grant_on_future    = true
}

# ------ silver ------
resource "snowflake_grant_privileges_to_account_role" "dbt_silver_db_usage" {
  account_role_name = snowflake_account_role.silver_transform_rw_role.name
  privileges        = ["USAGE", "CREATE SCHEMA"]

  on_account_object {
    object_type = "DATABASE"
    object_name = local.silver_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_silver_usage" {
  account_role_name = snowflake_account_role.silver_transform_rw_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = local.silver_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_cleansed_all" {
  account_role_name = snowflake_account_role.silver_transform_rw_role.name
  all_privileges    = true

  on_schema {
    schema_name = "${local.silver_db_name}.${local.silver_schema_name}"
  }
}

# ------ gold ------
resource "snowflake_grant_privileges_to_account_role" "dbt_gold_db_usage" {
  account_role_name = snowflake_account_role.gold_publish_rw_role.name
  privileges        = ["USAGE", "CREATE SCHEMA"]

  on_account_object {
    object_type = "DATABASE"
    object_name = local.gold_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_gold_usage" {
  account_role_name = snowflake_account_role.gold_publish_rw_role.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = local.gold_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_mart_all" {
  account_role_name = snowflake_account_role.gold_publish_rw_role.name
  all_privileges    = true

  on_schema {
    schema_name = "${local.gold_db_name}.${local.gold_schema_name}"
  }
}

# ============================================================
# Grants — streamlit Role
# ============================================================

# --- warehouse ---
resource "snowflake_grant_privileges_to_account_role" "streamlit_wh_usage" {
  account_role_name = snowflake_account_role.streamlit_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.streamlit_wh.name
  }
}

# --- gold ---
# データベースへのアクセス権限
resource "snowflake_grant_privileges_to_account_role" "streamlit_gold_db_usage" {
  account_role_name = snowflake_account_role.gold_consume_ro_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = local.gold_db_name
  }
}

# ターゲットスキーマへのアクセス権限
resource "snowflake_grant_privileges_to_account_role" "streamlit_gold_mart_usage" {
  account_role_name = snowflake_account_role.gold_consume_ro_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${local.gold_db_name}.${local.gold_schema_name}"
  }
}

# --- SELECT Privileges (Current & Future) ---
# 既存および将来作成される全てのテーブルへの参照権限
module "streamlit_gold_table_grants" {
  source = "./modules/schema_object_grants"

  account_role_name  = snowflake_account_role.gold_consume_ro_role.name
  in_schema          = "${local.gold_db_name}.${local.gold_schema_name}"
  object_type_plural = "TABLES"
  permission_level   = "SELECT"
  grant_on_all       = true
  grant_on_future    = true
}

# 既存および将来作成される全てのビューへの参照権限
module "streamlit_gold_view_grants" {
  source = "./modules/schema_object_grants"

  account_role_name  = snowflake_account_role.gold_consume_ro_role.name
  in_schema          = "${local.gold_db_name}.${local.gold_schema_name}"
  object_type_plural = "VIEWS"
  permission_level   = "SELECT"
  grant_on_all       = true
  grant_on_future    = true
}

# ============================================================
# Network Policy
# ============================================================

# ネットワークポリシー本体の定義
# resource "snowflake_network_policy" "api_access_policy" {
#   name    = "${local.env}_API_NETWORK_POLICY"
#   comment = "Allow access from specific CIDR blocks"
# 
#  # 例：特定のVPCやオフィスのIP
#   allowed_ip_list = ["1.2.3.4/32", "192.168.0.0/24"]
#    lifecycle {
#      prevent_destroy = false
#    }
# }

# ユーザーへの適用
# resource "snowflake_user_public_keys" "loader_user_network" {
#   # ...（既存のユーザー設定）...
# }