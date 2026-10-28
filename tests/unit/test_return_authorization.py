import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from armario_tablets.api.deps import get_services
from armario_tablets.api.main import create_app
from armario_tablets.config import get_settings


@pytest.mark.parametrize("tags", [[], ["AABBCCDD"]])
@pytest.mark.parametrize("authorization", [None, "Bearer forged", "Basic ignored"])
def test_manual_inventory_rejected_before_services(settings, tags, authorization):
    settings.admin_password = SecretStr("strong-test-password")
    settings.admin_token_secret = SecretStr("s" * 32)
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings

    def forbidden_services():
        pytest.fail("Rejected manual inventory reached services")

    app.dependency_overrides[get_services] = forbidden_services
    headers = {"Authorization": authorization} if authorization else {}
    with TestClient(app) as client:
        response = client.post(
            "/returns/reconcile",
            json={"session_id": 1, "event_id": "manual-event-001", "present_tags": tags},
            headers=headers,
        )
    assert response.status_code == 401


@pytest.mark.parametrize("body_tags", [{}, {"present_tags": None}])
def test_teacher_return_reads_server_inventory(services, settings, body_tags):
    from unittest.mock import Mock

    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings
    services.returns.reconcile = Mock(side_effect=RuntimeError("reader reached"))
    app.dependency_overrides[get_services] = lambda: services
    with TestClient(app) as client:
        with pytest.raises(RuntimeError, match="reader reached"):
            client.post(
                "/returns/reconcile",
                json={"session_id": 1, "event_id": "reader-event-001", **body_tags},
            )
    services.returns.reconcile.assert_called_once_with(1, "reader-event-001", None, source="api")
