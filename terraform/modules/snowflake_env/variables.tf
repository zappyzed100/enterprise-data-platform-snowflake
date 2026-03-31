variable "env" {
  type        = string
  description = "環境識別子 (DEV, PROD など)"

  validation {
    condition     = contains(["DEV", "PROD"], upper(var.env))
    error_message = "env は DEV または PROD を指定してください。"
  }
}

variable "bronze_db_name" {
  type        = string
  description = "Bronze DB 名"
}

variable "silver_db_name" {
  type        = string
  description = "Silver DB 名"
}

variable "gold_db_name" {
  type        = string
  description = "Gold DB 名"
}

variable "bronze_schema_name" {
  type        = string
  description = "Bronze schema 名"
}

variable "silver_schema_name" {
  type        = string
  description = "Silver schema 名"
}

variable "gold_schema_name" {
  type        = string
  description = "Gold schema 名"
}

variable "bronze_stage_name" {
  type        = string
  description = "Bronze stage 名"
}

variable "loader_user_name" {
  type        = string
  description = "Loader user 名"
}

variable "loader_role_name" {
  type        = string
  description = "Loader role 名"
}

variable "loader_warehouse_name" {
  type        = string
  description = "Loader warehouse 名"
}

variable "loader_file_format_name" {
  type        = string
  description = "Loader file format 名"
}

variable "dbt_user_name" {
  type        = string
  description = "dbt user 名"
}

variable "dbt_role_name" {
  type        = string
  description = "dbt role 名"
}

variable "dbt_warehouse_name" {
  type        = string
  description = "dbt warehouse 名"
}

variable "streamlit_user_name" {
  type        = string
  description = "Streamlit user 名"
}

variable "streamlit_role_name" {
  type        = string
  description = "Streamlit role 名"
}

variable "streamlit_warehouse_name" {
  type        = string
  description = "Streamlit warehouse 名"
}

variable "loader_user_rsa_public_key" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "LoaderユーザーのRSA公開鍵"
}

variable "dbt_user_rsa_public_key" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "dbtユーザーのRSA公開鍵"
}

variable "streamlit_user_rsa_public_key" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "dbtユーザーのRSA公開鍵"
}

variable "network_policy_allowed_ip_list" {
  type        = list(string)
  description = "network policy で許可する送信元CIDR"
  # Source: https://app.terraform.io/api/meta/ip-ranges (2026-03-31取得)
  default = [
    "75.2.98.97/32",
    "99.83.150.238/32",
    "52.86.200.106/32",
    "52.86.201.227/32",
    "52.70.186.109/32",
    "44.236.246.186/32",
    "54.185.161.84/32",
    "44.238.78.236/32",
    "184.73.220.168/32",
    "35.169.128.114/32",
    "52.45.167.229/32",
    "54.225.227.126/32",
    "44.224.173.58/32",
    "44.225.195.96/32",
    "52.37.251.66/32",
    "52.41.30.244/32",
  ]
}

variable "network_policy_blocked_ip_list" {
  type        = list(string)
  description = "network policy で拒否する送信元CIDR"
  default     = []
}
