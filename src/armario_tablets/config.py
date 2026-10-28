"""Configurações lidas do ambiente / arquivo .env (nunca hardcode de senhas)."""

from functools import lru_cache

from pydantic import AliasChoices, Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    mysql_database: str = Field(
        default="armario_tablets",
        validation_alias=AliasChoices("MYSQL_DATABASE", "MYSQL_DB", "mysql_database", "mysql_db"),
    )
    mysql_user: str = "armario"
    mysql_password: SecretStr | None = None
    mysql_host: str = "127.0.0.1"
    mysql_port: int = 3306
    # Se definida, tem prioridade sobre as variáveis MYSQL_* (útil em testes).
    database_url: str | None = None

    cabinet_code: str = "ARM-01"
    hardware_simulated: bool = True
    hardware_api_key: SecretStr | None = None
    lock_confirm_timeout_seconds: float = 5.0
    reservation_ttl_minutes: int = 10

    api_base_url: str = "http://127.0.0.1:8000"
    admin_username: str = "admin"
    admin_password: SecretStr | None = None
    admin_token_secret: SecretStr | None = None
    admin_session_ttl_minutes: int = Field(default=480, ge=1, le=1440)
    terminal_session_ttl_minutes: int = Field(default=480, ge=1, le=1440)
    professor_session_ttl_minutes: int = Field(default=10, ge=1, le=60)
    session_cookie_secure: bool = False  # Set true behind HTTPS outside local development.
    cors_allowed_origins: str = (
        "http://localhost:8080,http://127.0.0.1:8080,http://localhost:8502,http://127.0.0.1:8502"
    )
    log_level: str = "INFO"

    @property
    def mysql_db(self) -> str:
        """Compatibilidade reversa com acessos a settings.mysql_db."""
        return self.mysql_database

    @property
    def sqlalchemy_url(self) -> str | URL:
        """URL do banco; monta a partir de MYSQL_* se DATABASE_URL não existir."""
        if self.database_url:
            return self.database_url
        if self.mysql_password is None:
            raise ValueError(
                "MYSQL_PASSWORD não definida. Copie .env.example para .env e preencha."
            )
        return URL.create(
            "mysql+pymysql",
            username=self.mysql_user,
            password=self.mysql_password.get_secret_value(),
            host=self.mysql_host,
            port=self.mysql_port,
            database=self.mysql_database,
            query={"charset": "utf8mb4"},
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
