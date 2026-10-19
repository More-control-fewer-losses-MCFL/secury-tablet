"""Fixtures compartilhadas.

A fixture `db` é definida em unit/ (SQLite) e em integration/ (PostgreSQL).
"""

import pytest

from armario_tablets.config import Settings
from armario_tablets.integrations.simulated_hardware import build_simulated_hardware
from armario_tablets.services.factory import build_services
from tests.factories import CABINET_CODE, seed_basic


@pytest.fixture
def settings() -> Settings:
    return Settings(
        _env_file=None,
        database_url="sqlite://",
        cabinet_code=CABINET_CODE,
        lock_confirm_timeout_seconds=0.05,
    )


@pytest.fixture
def hardware():
    return build_simulated_hardware()


@pytest.fixture
def services(db, hardware, settings):
    seed_basic(db)
    return build_services(db, hardware, settings, poll_interval_seconds=0.01)
