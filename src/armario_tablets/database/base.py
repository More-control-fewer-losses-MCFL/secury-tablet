"""Base declarativa do SQLAlchemy, com nomes de constraints previsíveis (bom para Alembic)."""

from sqlalchemy import JSON, MetaData
from sqlalchemy.orm import DeclarativeBase

NAMING_CONVENTION = {
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

# MySQL 8.4 utiliza JSON nativo; o padrão JSON também funciona em SQLite e nos testes.
JSONType = JSON()


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)
