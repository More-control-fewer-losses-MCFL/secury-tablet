import time

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import select

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.main import create_app
from armario_tablets.api.operational_auth import TERMINAL_COOKIE, sign_claims
from armario_tablets.config import get_settings
from armario_tablets.models import Cabinet, CheckoutSession, Professor
from tests.factories import ACTIVE_BADGE, INACTIVE_BADGE, OTHER_ACTIVE_BADGE


@pytest.fixture
def auth_client(services, settings, db):
    settings.admin_password = SecretStr("test-administrator-password")
    settings.admin_token_secret = SecretStr("a" * 32)
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_services] = lambda: services
    with TestClient(app) as client:
        yield client


def admin_headers(client):
    token = client.post(
        "/admin/login", json={"username": "admin", "password": "test-administrator-password"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def teacher_headers(client, badge=ACTIVE_BADGE):
    assert client.post("/terminal/authorize", headers=admin_headers(client)).status_code == 200
    response = client.post("/auth/rfid", json={"badge_uid": badge})
    assert response.status_code == 200
    return {"Authorization": "Bearer " + response.json()["access_token"]}


@pytest.mark.parametrize(
    "method,path,body",
    [
        ("GET", "/tablets", None),
        ("GET", "/tablets/available", None),
        ("GET", "/history", None),
        ("GET", "/professors/by-badge/DE000001", None),
        (
            "POST",
            "/checkout-requests",
            {"badge_uid": ACTIVE_BADGE, "quantity": 1, "purpose": "Aula"},
        ),
        ("POST", "/returns/reconcile", {"session_id": 1, "event_id": "return-001"}),
    ],
)
def test_anonymous_operations_fail_before_services(auth_client, method, path, body):
    def forbidden():
        pytest.fail("Unauthorized operation constructed services")

    auth_client.app.dependency_overrides[get_services] = forbidden
    response = auth_client.request(method, path, json=body)
    assert response.status_code == 401


def test_uid_alone_cannot_create_session(auth_client):
    response = auth_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE})
    assert response.status_code == 401


def test_terminal_cookie_is_http_only_and_bounded(auth_client):
    response = auth_client.post("/terminal/authorize", headers=admin_headers(auth_client))
    cookie = response.headers["set-cookie"].lower()
    assert "httponly" in cookie and "samesite=strict" in cookie
    assert "max-age=28800" in cookie


def test_terminal_and_teacher_tokens_do_not_grant_admin(auth_client):
    teacher = teacher_headers(auth_client)
    assert auth_client.post("/terminal/authorize", headers=teacher).status_code == 401
    cookie = auth_client.cookies.get(TERMINAL_COOKIE)
    assert (
        auth_client.get("/admin/session", headers={"Authorization": f"Bearer {cookie}"}).status_code
        == 401
    )


def test_teacher_cannot_switch_badge_or_read_other_profile(auth_client):
    headers = teacher_headers(auth_client)
    response = auth_client.post(
        "/checkout-requests",
        headers=headers,
        json={"badge_uid": OTHER_ACTIVE_BADGE, "quantity": 1, "purpose": "Aula"},
    )
    assert response.status_code == 403
    assert (
        auth_client.get(f"/professors/by-badge/{OTHER_ACTIVE_BADGE}", headers=headers).status_code
        == 403
    )


def test_history_is_scoped_and_returns_reject_other_owner(auth_client, db):
    professors = list(db.scalars(select(Professor).where(Professor.active).order_by(Professor.id)))
    cabinet = db.scalar(select(Cabinet))
    sessions = [
        CheckoutSession(
            professor_id=p.id,
            cabinet_id=cabinet.id,
            requested_quantity=1,
            purpose="Aula",
            status="OPEN",
        )
        for p in professors
    ]
    db.add_all(sessions)
    db.commit()
    headers = teacher_headers(auth_client)
    page = auth_client.get("/history", headers=headers).json()
    assert page["total"] == 1 and page["rows"][0]["session_id"] == sessions[0].id
    assert (
        auth_client.get(
            "/history", params={"professor_id": professors[1].id}, headers=headers
        ).status_code
        == 403
    )
    assert (
        auth_client.post(
            "/returns/reconcile",
            headers=headers,
            json={"session_id": sessions[1].id, "event_id": "other-return-001"},
        ).status_code
        == 403
    )
    own = auth_client.post(
        "/returns/reconcile",
        headers=headers,
        json={"session_id": sessions[0].id, "event_id": "own-return-001"},
    )
    assert own.status_code == 200


@pytest.mark.parametrize("tags", [[], ["AA000001"]])
def test_teacher_cannot_override_inventory(auth_client, tags):
    headers = teacher_headers(auth_client)
    assert (
        auth_client.post(
            "/returns/reconcile",
            headers=headers,
            json={"session_id": 1, "event_id": "manual-001", "present_tags": tags},
        ).status_code
        == 403
    )


def test_teacher_can_checkout_without_password(auth_client):
    headers = teacher_headers(auth_client)
    response = auth_client.post(
        "/checkout-requests",
        headers=headers,
        json={"badge_uid": ACTIVE_BADGE, "quantity": 1, "purpose": "Aula"},
    )
    assert response.status_code == 201 and response.json()["status"] == "UNLOCKED"


def test_inactive_and_unknown_badges_cannot_login(auth_client):
    auth_client.post("/terminal/authorize", headers=admin_headers(auth_client))
    assert auth_client.post("/auth/rfid", json={"badge_uid": INACTIVE_BADGE}).status_code == 403
    assert auth_client.post("/auth/rfid", json={"badge_uid": "DEADBEEF"}).status_code == 404


def test_expired_tampered_and_copied_sessions_rejected(auth_client, settings):
    headers = teacher_headers(auth_client)
    assert (
        auth_client.get(
            "/history", headers={"Authorization": headers["Authorization"] + "x"}
        ).status_code
        == 401
    )
    expired = sign_claims({"role": "professor", "sub": 1, "exp": int(time.time()) - 1}, settings)
    assert (
        auth_client.get("/history", headers={"Authorization": "Bearer " + expired}).status_code
        == 401
    )
    auth_client.cookies.clear()
    assert auth_client.get("/history", headers=headers).status_code == 401


def test_terminal_revocation_invalidates_copied_cookie(auth_client):
    headers = teacher_headers(auth_client)
    cookie = auth_client.cookies.get(TERMINAL_COOKIE)
    assert (
        auth_client.post("/terminal/revoke", headers=admin_headers(auth_client)).status_code == 200
    )
    auth_client.cookies.set(TERMINAL_COOKIE, cookie)
    assert auth_client.get("/history", headers=headers).status_code == 401


def test_deactivating_professor_invalidates_session(auth_client, db):
    headers = teacher_headers(auth_client)
    professor = db.scalar(select(Professor).where(Professor.badge_uid == ACTIVE_BADGE))
    professor.active = False
    db.commit()
    assert auth_client.get("/history", headers=headers).status_code == 403


@pytest.mark.parametrize("kind", ["expired", "tampered", "unregistered", "wrong-role"])
def test_invalid_terminal_cannot_login(auth_client, settings, kind):
    teacher_headers(auth_client)
    cookie = auth_client.cookies.get(TERMINAL_COOKIE)
    if kind == "tampered":
        cookie += "x"
    else:
        cookie = sign_claims(
            {
                "role": "admin" if kind == "wrong-role" else "terminal",
                "sub": "not-registered",
                "exp": int(time.time()) + (-1 if kind == "expired" else 60),
            },
            settings,
        )
    auth_client.cookies.clear()
    auth_client.cookies.set(TERMINAL_COOKIE, cookie)
    assert auth_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE}).status_code == 401
