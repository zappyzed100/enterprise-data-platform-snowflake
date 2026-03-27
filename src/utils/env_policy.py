import os


def is_ci_environment() -> bool:
    """Return True when running in a CI execution context."""
    ci_markers = (
        os.getenv("CI", ""),
        os.getenv("GITHUB_ACTIONS", ""),
        os.getenv("TF_BUILD", ""),
        os.getenv("BUILDKITE", ""),
        os.getenv("GITLAB_CI", ""),
    )
    return any(marker.strip().lower() == "true" for marker in ci_markers)


def assert_prod_access_allowed(app_env: str, context: str) -> None:
    """Block prod operations outside CI.

    Args:
        app_env: Environment name. Expected values are dev/prod (case-insensitive).
        context: Human readable operation name for error messages.
    """
    env = app_env.strip().lower()
    if env != "prod":
        return

    if not is_ci_environment():
        raise RuntimeError(
            f"{context}: APP_ENV=prod は CI 環境でのみ許可されています。ローカル実行は APP_ENV=dev を使用してください。"
        )
