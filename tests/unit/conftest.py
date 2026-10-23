"""Testes unitários: SQLite em memória, rápido e sem depender de PostgreSQL."""

import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import armario_tablets.models  # noqa: F401
from armario_tablets.database.base import Base


@pytest.fixture
def engine():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )

    # Recomendação do SQLAlchemy para o SAVEPOINT/transações funcionarem direito no pysqlite.
    @event.listens_for(engine, "connect")
    def _no_implicit_begin(dbapi_connection, _):
        dbapi_connection.isolation_level = None

    @event.listens_for(engine, "begin")
    def _emit_begin(connection):
        connection.exec_driver_sql("BEGIN")

    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()


@pytest.fixture
def db(engine):
    session = sessionmaker(bind=engine, expire_on_commit=False)()
    yield session
    session.close()
