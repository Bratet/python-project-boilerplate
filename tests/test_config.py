import os
from unittest.mock import patch

from app.config import Settings


def test_default_values() -> None:
    settings = Settings()
    assert settings.app_env == "dev"
    assert settings.app_name == "app"
    assert settings.log_level == "info"
    assert settings.app_port == 8000
    assert settings.debug is False


def test_from_env_vars() -> None:
    env_vars = {
        "APP_ENV": "production",
        "APP_NAME": "my-service",
        "LOG_LEVEL": "debug",
        "APP_PORT": "8080",
        "DEBUG": "true",
    }
    with patch.dict(os.environ, env_vars):
        settings = Settings()
        assert settings.app_env == "production"
        assert settings.app_name == "my-service"
        assert settings.log_level == "debug"
        assert settings.app_port == 8080
        assert settings.debug is True


def test_singleton_settings() -> None:
    from app.config import settings

    assert isinstance(settings, Settings)
    assert settings.app_env == "dev"
