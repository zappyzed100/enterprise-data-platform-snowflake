#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

run_console() {
  local app_env="$1"
  local expression="$2"

  printf '%s\n' "$expression" \
    | TF_VAR_app_env="$app_env" terraform -chdir=terraform console -var-file=common.auto.tfvars \
    | tr -d '\r' \
    | sed -e 's/^"//' -e 's/"$//'
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$expected" != "$actual" ]]; then
    echo "[ng] $label expected=$expected actual=$actual" >&2
    exit 1
  fi

  echo "[ok] $label => $actual"
}

prod_dbt_user="$(run_console prod local.dbt_user_name)"
dev_dbt_user="$(run_console dev local.dbt_user_name)"
prod_loader_user="$(run_console prod local.loader_user_name)"
dev_loader_user="$(run_console dev local.loader_user_name)"

assert_equals "PROD_DBT_USER" "$prod_dbt_user" "app_env=prod local.dbt_user_name"
assert_equals "DEV_DBT_USER" "$dev_dbt_user" "app_env=dev local.dbt_user_name"
assert_equals "PROD_LOADER_USER" "$prod_loader_user" "app_env=prod local.loader_user_name"
assert_equals "DEV_LOADER_USER" "$dev_loader_user" "app_env=dev local.loader_user_name"

echo "[ok] terraform env selection check passed"
