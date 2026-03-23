# terraform/providers.tf
terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.13.0" # 使用するバージョンを指定
    }
  }
}

provider "snowflake" {
  # 環境変数 SNOWFLAKE_ACCOUNT の値を明示的に割り当てる
  # もしくは、この行を削除して環境変数を下記の名前に変更する
  organization_name = var.snowflake_organization_name
  account_name = var.snowflake_account_name
  role    = "ACCOUNTADMIN"

  # プレビュー機能を有効化する設定を追加
  preview_features_enabled = [
    "snowflake_table_resource",
    "snowflake_stage_internal_resource",
    "snowflake_file_format_resource"
  ]
}