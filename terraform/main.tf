# DEV 環境 — modules/snowflake_env を呼び出す
module "dev" {
  source = "./modules/snowflake_env"

  env                  = "DEV"
  loader_user_password = var.dev_loader_user_password
  dbt_user_password    = var.dev_dbt_user_password
}
