"""Ambiente do Alembic: lê a URL do banco das configurações (.env)."""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine

import armario_tablets.models  # noqa: F401  (registra as tabelas no metadata)
from armario_tablets.config import get_settings
from armario_tablets.database.base import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=str(get_settings().sqlalchemy_url),
        target_metadata=target_metadata,
        literal_binds=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    engine = create_engine(get_settings().sqlalchemy_url, pool_pre_ping=True)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
