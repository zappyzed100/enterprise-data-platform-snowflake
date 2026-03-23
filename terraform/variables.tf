# terraform/variables.tf
variable "dev_loader_user_password" {
  type      = string
  sensitive = true
}

variable "dev_dbt_user_password" {
  type      = string
  sensitive = true
}

variable "snowflake_organization_name" {
  type        = string
  description = "Snowflakeの組織名"
}

variable "snowflake_account_name" {
  type        = string
  description = "Snowflakeのアカウント名"
}