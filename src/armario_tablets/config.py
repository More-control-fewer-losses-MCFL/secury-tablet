"""Configurações lidas do ambiente / arquivo .env (nunca hardcode de senhas)."""

from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    postgres_db: str = "armario_tablets"
    postgres_user: str = "armario"
    postgres_password: SecretStr | None = None
    postgres_host: str = "127.0.0.1"
    postgres_port: int = 5432
    # Se definida, tem prioridade sobre as variáveis POSTGRES_* (útil em testes).
    database_url: str | None = None

    cabinet_code: str = "ARM-01"
    hardware_simulated: bool = True
    lock_confirm_timeout_seconds: float = 5.0
    reservation_ttl_minutes: int = 10

    api_base_url: str = "http://127.0.0.1:8000"
    log_level: str = "INFO"

    @property
    def sqlalchemy_url(self) -> str | URL:
        """URL do banco; monta a partir de POSTGRES_* se DATABASE_URL não existir."""
        if self.database_url:
            return self.database_url
        if self.postgres_password is None:
            raise ValueError(
                "POSTGRES_PASSWORD não definida. Copie .env.example para .env e preencha."
            )
        return URL.create(
            "postgresql+psycopg",
            username=self.postgres_user,
            password=self.postgres_password.get_secret_value(),
            host=self.postgres_host,
            port=self.postgres_port,
            database=self.postgres_db,
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
