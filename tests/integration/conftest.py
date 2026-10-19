"""Testes de integração: MySQL real, SEPARADO do banco de desenvolvimento.

Defina TEST_DATABASE_URL apontando para um banco de teste (nunca o banco real),
por exemplo: mysql+pymysql://armario:sua_senha@127.0.0.1:3306/armario_tablets_test
Sem a variável, estes testes são pulados. O schema é criado pelas migrações do Alembic.
"""

import os
import subprocess
import sys
from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from armario_tablets.config import Settings
from armario_tablets.integrations.simulated_hardware import build_simulated_hardware
from armario_tablets.services.factory import build_services
from tests.factories import CABINET_CODE

ROOT = Path(__file__).resolve().parents[2]
TEST_URL = os.environ.get("TEST_DATABASE_URL")

pytestmark = pytest.mark.integration


def pytest_collection_modifyitems(config, items):
    if TEST_URL:
        return
    skip = pytest.mark.skip(reason="defina TEST_DATABASE_URL para rodar testes de integração")
    for item in items:
        if "integration" in str(item.fspath):
            item.add_marker(skip)


@pytest.fixture(scope="session")
def mysql_engine():
    if not TEST_URL:
        pytest.skip("TEST_DATABASE_URL não definida")
    engine = create_engine(TEST_URL, pool_pre_ping=True, isolation_level="READ COMMITTED")
    with engine.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        conn.execute(
            text(
                "DROP TABLE IF EXISTS events, checkout_items, checkout_sessions, "
                "tablets, professors, cabinets, alembic_version"
            )
        )
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    env = {**os.environ, "DATABASE_URL": TEST_URL, "PYTHONPATH": str(ROOT / "src")}
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
    )
    yield engine
    engine.dispose()


@pytest.fixture
def session_factory(mysql_engine):
    with mysql_engine.begin() as conn:
        conn.execute(text("SET SESSION innodb_lock_wait_timeout = 5"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        conn.execute(text("TRUNCATE events"))
        conn.execute(text("TRUNCATE checkout_items"))
        conn.execute(text("TRUNCATE checkout_sessions"))
        conn.execute(text("TRUNCATE tablets"))
        conn.execute(text("TRUNCATE professors"))
        conn.execute(text("TRUNCATE cabinets"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    return sessionmaker(bind=mysql_engine, expire_on_commit=False)


@pytest.fixture
def db(session_factory):
    session = session_factory()
    yield session
    session.close()


@pytest.fixture
def mysql_settings() -> Settings:
    return Settings(
        _env_file=None,
        database_url=TEST_URL or "sqlite://",
        cabinet_code=CABINET_CODE,
        lock_confirm_timeout_seconds=0.05,
    )


@pytest.fixture
def open_services(session_factory, mysql_settings):
    """Abre sessões+serviços independentes (uma por thread) e fecha todas no final.

    Sessões esquecidas abertas manteriam locks e travariam o TRUNCATE do próximo teste.
    """
    opened = []

    def _open():
        session = session_factory()
        opened.append(session)
        services = build_services(
            session,
            build_simulated_hardware(),
            mysql_settings,
            poll_interval_seconds=0.01,
        )
        return session, services

    yield _open
    for session in opened:
        session.close()
