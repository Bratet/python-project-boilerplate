from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    app_env: str = "dev"
    app_name: str = "app"
    log_level: str = "info"
    app_port: int = 8000
    debug: bool = False


settings = Settings()
