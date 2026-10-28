"""Chamadas rejeitadas não podem sequer montar os serviços de banco/hardware."""

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from armario_tablets.api.deps import get_services
from armario_tablets.api.main import create_app
from armario_tablets.config import get_settings


@pytest.mark.parametrize(
    ("configured", "supplied", "status"),
    [
        (None, None, 503),
        ("short", "short", 503),
        ("k" * 32, None, 401),
        ("k" * 32, "wrong", 401),
    ],
)
def test_rejected_controller_never_calls_services(settings, configured, supplied, status):
    settings.hardware_api_key = SecretStr(configured) if configured else None
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings

    def forbidden_services():
        pytest.fail("Uma requisição rejeitada tentou acessar serviços.")

    app.dependency_overrides[get_services] = forbidden_services
    headers = {"X-Hardware-Key": supplied} if supplied else {}
    with TestClient(app) as client:
        response = client.post("/hardware/events", headers=headers, json={})
    assert response.status_code == status


def test_admin_bearer_cannot_replace_controller_key(settings):
    settings.hardware_api_key = SecretStr("k" * 32)
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings
    with TestClient(app) as client:
        response = client.post(
            "/hardware/events", headers={"Authorization": "Bearer arbitrary"}, json={}
        )
    assert response.status_code == 401
