variable "env" {
  type        = string
  description = "環境識別子 (DEV, PROD など)"

  validation {
    condition     = contains(["DEV", "PROD"], upper(var.env))
    error_message = "env は DEV または PROD を指定してください。"
  }
}

variable "loader_user_password" {
  type        = string
  sensitive   = true
  description = "Loaderユーザーのパスワード"
}

variable "dbt_user_password" {
  type        = string
  sensitive   = true
  description = "dbtユーザーのパスワード"
}
