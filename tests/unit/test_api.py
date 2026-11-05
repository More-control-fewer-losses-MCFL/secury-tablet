"""Testes dos endpoints HTTP (SQLite em memória + hardware simulado)."""

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.main import create_app
from armario_tablets.config import get_settings
from armario_tablets.services.factory import build_services
from tests.factories import ACTIVE_BADGE, INACTIVE_BADGE, all_tags, tag_for


@pytest.fixture
def client(services, db, hardware, settings):
    settings.hardware_api_key = SecretStr("test-controller-key-with-at-least-32-bytes")
    settings.admin_password = SecretStr("default-test-admin-password")
    settings.admin_token_secret = SecretStr("s" * 32)
    app = create_app()
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_services] = lambda: build_services(
        db, hardware, settings, poll_interval_seconds=0.01
    )
    client = TestClient(
        app, headers={"X-Hardware-Key": settings.hardware_api_key.get_secret_value()}
    )
    token = client.post(
        "/admin/login", json={"username": "admin", "password": "default-test-admin-password"}
    ).json()["access_token"]
    client.headers["Authorization"] = f"Bearer {token}"
    return client


def checkout(client, quantity=2, badge=ACTIVE_BADGE):
    return client.post(
        "/checkout-requests",
        json={"badge_uid": badge, "quantity": quantity, "purpose": "Aula de campo"},
    )


def hardware_event(client, session_id, event_id, present, kind="INVENTORY_AFTER_CHECKOUT"):
    return client.post(
        "/hardware/events",
        json={
            "event_id": event_id,
            "cabinet_code": "ARM-TEST",
            "type": kind,
            "occurred_at": "2026-10-15T12:00:00Z",
            "session_id": session_id,
            "details": {"present_tags": sorted(present)},
        },
    )


def test_health(client):
    assert client.get("/health").json() == {"status": "ok", "database": "ok"}


def test_cors_allows_configured_flutter_web_origin(client):
    response = client.options(
        "/health",
        headers={
            "Origin": "http://localhost:8502",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "content-type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:8502"


def test_cors_allows_authorization_header_for_flutter_admin_login(client):
    response = client.options(
        "/admin/login",
        headers={
            "Origin": "http://localhost:8502",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )

    assert response.status_code == 200
    assert "authorization" in response.headers["access-control-allow-headers"].lower()


def test_admin_login_is_disabled_without_server_credentials(client, settings):
    settings.admin_password = None
    response = client.post("/admin/login", json={"username": "admin", "password": "anything"})

    assert response.status_code == 503
    assert "ADMIN_PASSWORD" in response.json()["detail"]


def test_admin_login_issues_expiring_signed_session(client, settings):
    settings.admin_password = SecretStr("a-long-test-password")
    settings.admin_token_secret = SecretStr("test-signing-secret-that-is-at-least-32-bytes")

    login = client.post(
        "/admin/login",
        json={"username": "admin", "password": "a-long-test-password"},
    )

    assert login.status_code == 200
    body = login.json()
    assert body["token_type"] == "bearer"
    assert body["expires_in"] == 8 * 60 * 60
    assert "password" not in body

    session = client.get(
        "/admin/session", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert session.json() == {"username": "admin", "role": "admin"}


def test_admin_login_rejects_bad_credentials_and_tampered_token(client, settings):
    settings.admin_password = SecretStr("a-long-test-password")
    settings.admin_token_secret = SecretStr("test-signing-secret-that-is-at-least-32-bytes")

    rejected = client.post("/admin/login", json={"username": "admin", "password": "wrong-password"})
    assert rejected.status_code == 401

    accepted = client.post(
        "/admin/login",
        json={"username": "admin", "password": "a-long-test-password"},
    )
    token = accepted.json()["access_token"]
    invalid = client.get("/admin/session", headers={"Authorization": f"Bearer {token}tampered"})
    assert invalid.status_code == 401


def test_cors_rejects_unconfigured_origin(client):
    response = client.options(
        "/health",
        headers={
            "Origin": "https://untrusted.example",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers


def test_available_tablets(client):
    body = client.get("/tablets/available").json()
    assert body["available"] == 5
    assert "rfid_tag_uid" not in body["tablets"][0]


def test_list_tablets_with_status_filter(client):
    assert len(client.get("/tablets").json()) == 5
    assert client.get("/tablets", params={"status": "CHECKED_OUT"}).json() == []


def test_professor_by_badge(client):
    assert client.get(f"/professors/by-badge/{ACTIVE_BADGE}").json()["name"] == "Ana Teste"
    assert client.get("/professors/by-badge/DEADBEEF").status_code == 404
    assert client.get(f"/professors/by-badge/{INACTIVE_BADGE}").status_code == 403
    assert client.get("/professors/by-badge/xyz").status_code == 422


def test_checkout_request_created(client):
    response = checkout(client)
    assert response.status_code == 201
    assert response.json()["status"] == "UNLOCKED"
    assert response.json()["taken_quantity"] == 0


def test_checkout_request_errors(client):
    assert checkout(client, quantity=99).status_code == 422  # validação do schema (<= 50)
    assert checkout(client, quantity=6).status_code == 409  # acima da disponibilidade
    assert checkout(client, badge=INACTIVE_BADGE).status_code == 403


def test_full_flow_with_duplicate_event(client):
    session_id = checkout(client).json()["session_id"]
    present = all_tags() - {tag_for(1), tag_for(2)}

    first = hardware_event(client, session_id, "evt-http-000001", present)
    again = hardware_event(client, session_id, "evt-http-000001", present)
    assert first.json()["duplicate"] is False
    assert again.json()["duplicate"] is True
    assert client.get("/tablets/available").json()["available"] == 3

    reconcile = client.post(
        "/returns/reconcile",
        json={
            "session_id": session_id,
            "event_id": "evt-http-000002",
            "present_tags": sorted(all_tags() - {tag_for(2)}),
        },
    )
    assert reconcile.status_code == 200
    assert reconcile.json()["status"] == "DIVERGENT"
    assert reconcile.json()["pending_quantity"] == 1


def test_inventory_event_without_session_is_404(client):
    response = hardware_event(client, None, "evt-http-000003", all_tags())
    assert response.status_code == 404


def test_door_event_is_idempotent(client):
    body = {
        "event_id": "evt-door-000001",
        "cabinet_code": "ARM-TEST",
        "type": "DOOR_OPENED",
        "occurred_at": "2026-10-15T12:00:00Z",
    }
    assert client.post("/hardware/events", json=body).json()["duplicate"] is False
    assert client.post("/hardware/events", json=body).json()["duplicate"] is True


def test_lock_error_event_fails_the_session(client):
    session_id = checkout(client).json()["session_id"]
    response = client.post(
        "/hardware/events",
        json={
            "event_id": "evt-lock-000001",
            "cabinet_code": "ARM-TEST",
            "type": "LOCK_ERROR",
            "occurred_at": "2026-10-15T12:00:00Z",
            "session_id": session_id,
            "details": {"message": "porta emperrada"},
        },
    )
    assert response.status_code == 200
    history = client.get("/history", params={"status": "FAILED"}).json()
    assert history["total"] == 1


def test_history_pagination(client):
    for _ in range(3):
        sid = checkout(client, quantity=1).json()["session_id"]
        hardware_event(client, sid, f"evt-hist-{sid:06d}", all_tags())  # nada retirado
    page = client.get("/history", params={"limit": 2, "offset": 0}).json()
    assert page["total"] == 3
    assert len(page["rows"]) == 2
    assert client.get("/history", params={"limit": 500}).status_code == 422


def test_unknown_cabinet_in_event_is_404(client):
    response = client.post(
        "/hardware/events",
        json={
            "event_id": "evt-cab-0000001",
            "cabinet_code": "NAO-EXISTE",
            "type": "DOOR_OPENED",
            "occurred_at": "2026-10-15T12:00:00Z",
        },
    )
    assert response.status_code == 404
