locals {
  app_env_upper = upper(var.app_env)

  selected_loader_user_rsa_public_key = coalesce(
    var.loader_user_rsa_public_key,
    local.app_env_upper == "PROD" ? var.prod_loader_user_rsa_public_key : var.dev_loader_user_rsa_public_key,
  )
  selected_dbt_user_rsa_public_key = coalesce(
    var.dbt_user_rsa_public_key,
    local.app_env_upper == "PROD" ? var.prod_dbt_user_rsa_public_key : var.dev_dbt_user_rsa_public_key,
  )
  selected_streamlit_user_rsa_public_key = coalesce(
    var.streamlit_user_rsa_public_key,
    local.app_env_upper == "PROD" ? var.prod_streamlit_user_rsa_public_key : var.dev_streamlit_user_rsa_public_key,
  )
}

# module 名を dev -> snowflake_env へ変更した際の state 移行
moved {
  from = module.dev
  to   = module.snowflake_env
}

# APP_ENV に応じて DEV / PROD の Snowflake リソースを作成
module "snowflake_env" {
  source = "./modules/snowflake_env"

  env                           = local.app_env_upper
  loader_user_rsa_public_key    = local.selected_loader_user_rsa_public_key
  dbt_user_rsa_public_key       = local.selected_dbt_user_rsa_public_key
  streamlit_user_rsa_public_key = local.selected_streamlit_user_rsa_public_key
}
