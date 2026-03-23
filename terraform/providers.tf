# terraform/providers.tf
terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.13.0" # 使用するバージョンを指定
    }
  }

  # organization / workspaces は backend.hcl (gitignore対象) から注入する
  backend "remote" {}
}

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  role              = "ACCOUNTADMIN"

  # プレビュー機能を有効化する設定を追加
  preview_features_enabled = [
    "snowflake_table_resource",
    "snowflake_stage_internal_resource",
    "snowflake_file_format_resource"
  ]
}