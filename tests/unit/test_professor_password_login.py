import time

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import select

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.main import create_app
from armario_tablets.api.operational_auth import sign_claims
from armario_tablets.config import get_settings
from armario_tablets.models import Cabinet, CheckoutSession, Professor, ProfessorCredential
from armario_tablets.utils.passwords import hash_password, verify_password
from tests.factories import ACTIVE_BADGE, OTHER_ACTIVE_BADGE

PASSWORD = "fictional-professor-password"


@pytest.fixture
def login_client(services, settings, db):
    settings.admin_password = SecretStr("fictional-administrator-password")
    settings.admin_token_secret = SecretStr("x" * 32)
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_services] = lambda: services
    with TestClient(app) as client:
        yield client


def admin(client):
    response = client.post(
        "/admin/login", json={"username": "admin", "password": "fictional-administrator-password"}
    )
    return {"Authorization": "Bearer " + response.json()["access_token"]}


def professor_id(db, badge=ACTIVE_BADGE):
    return db.scalar(select(Professor.id).where(Professor.badge_uid == badge))


def provision(client, db, *, username="teacher.ana", password=PASSWORD, badge=ACTIVE_BADGE):
    return client.post(
        f"/admin/professors/{professor_id(db, badge)}/credentials",
        headers=admin(client),
        json={"username": username, "password": password},
    )


def login(client, *, username="teacher.ana", password=PASSWORD):
    return client.post("/auth/professor/login", json={"username": username, "password": password})


def headers(response):
    assert response.status_code == 200
    return {"Authorization": "Bearer " + response.json()["access_token"]}


def test_hashes_have_random_salt_and_reject_malformed_hashes():
    first, second = hash_password(PASSWORD), hash_password(PASSWORD)
    assert first != second and PASSWORD not in first
    assert verify_password(PASSWORD, first)
    assert not verify_password("incorrect", first)
    assert not verify_password(PASSWORD, first.replace("16384", "999999999"))
    assert not verify_password(PASSWORD, "malformed")


def test_admin_provisions_credentials_without_returning_secrets(login_client, db):
    response = provision(login_client, db, username=" Teacher.Ana ")
    assert response.status_code == 200
    assert response.json() == {"professor_id": professor_id(db), "username": "teacher.ana"}
    stored = db.get(ProfessorCredential, professor_id(db))
    assert stored.password_hash.startswith("scrypt$")
    assert PASSWORD not in stored.password_hash
    assert "password" not in response.text and "revision" not in response.text


def test_password_login_without_terminal_receives_only_teacher_privileges(login_client, db):
    provision(login_client, db)
    response = login(login_client, username="TEACHER.ANA")
    teacher = headers(response)
    assert response.headers["cache-control"] == "no-store"
    assert response.json()["expires_in"] == 600
    assert "password" not in response.json() and "badge_uid" not in response.json()["professor"]
    session = login_client.get("/auth/professor/session", headers=teacher)
    assert session.status_code == 200 and session.json()["role"] == "professor"
    assert session.json()["professor"]["id"] == professor_id(db)
    available = login_client.get("/tablets/available", headers=teacher)
    assert available.status_code == 200 and available.json()["tablets"] == []
    assert login_client.get("/tablets", headers=teacher).status_code == 403
    assert login_client.get("/admin/session", headers=teacher).status_code == 401
    assert login_client.post("/terminal/authorize", headers=teacher).status_code == 401
    assert login_client.get("/admin/overview", headers=teacher).status_code == 401


def test_unknown_wrong_password_and_inactive_account_have_same_error(login_client, db):
    provision(login_client, db)
    responses = [
        login(login_client, username="not.present"),
        login(login_client, password="incorrect"),
    ]
    professor = db.get(Professor, professor_id(db))
    professor.active = False
    db.commit()
    responses.append(login(login_client))
    assert [response.status_code for response in responses] == [401, 401, 401]
    assert all(response.json() == responses[0].json() for response in responses)
    assert all(PASSWORD not in response.text for response in responses)


def test_reset_invalidates_old_token_and_old_password(login_client, db):
    provision(login_client, db)
    old = headers(login(login_client))
    assert (
        provision(login_client, db, password="new-fictional-professor-password").status_code == 200
    )
    assert login_client.get("/history", headers=old).status_code == 401
    assert login(login_client).status_code == 401
    assert login(login_client, password="new-fictional-professor-password").status_code == 200


def test_deactivation_revokes_password_session(login_client, db):
    provision(login_client, db)
    teacher = headers(login(login_client))
    professor = db.get(Professor, professor_id(db))
    professor.active = False
    db.commit()
    assert login_client.get("/history", headers=teacher).status_code == 403


def test_username_conflict_rolls_back_without_reassigning_account(login_client, db):
    provision(login_client, db)
    assert (
        provision(login_client, db, username="TEACHER.ANA", badge=OTHER_ACTIVE_BADGE).status_code
        == 409
    )
    assert db.get(ProfessorCredential, professor_id(db, OTHER_ACTIVE_BADGE)) is None
    assert login(login_client).status_code == 200


def test_only_admin_can_provision_credentials(login_client, db):
    path = f"/admin/professors/{professor_id(db)}/credentials"
    payload = {"username": "teacher.ana", "password": PASSWORD}
    assert login_client.post(path, json=payload).status_code == 401
    provision(login_client, db)
    assert (
        login_client.post(path, json=payload, headers=headers(login(login_client))).status_code
        == 403
    )


@pytest.mark.parametrize("password", ["too-short", "x" * 257])
def test_password_validation_does_not_echo_input(login_client, db, password):
    response = provision(login_client, db, password=password)
    assert response.status_code == 422
    assert password not in response.text
    assert all("input" not in error for error in response.json()["detail"])


def test_login_validation_does_not_echo_password(login_client):
    password = "sensitive-invalid-password" * 20
    response = login_client.post(
        "/auth/professor/login", json={"username": "bad@user", "password": password}
    )
    assert response.status_code == 422 and password not in response.text


def test_missing_professor_is_not_silently_created(login_client):
    response = login_client.post(
        "/admin/professors/999999/credentials",
        headers=admin(login_client),
        json={"username": "teacher.ana", "password": PASSWORD},
    )
    assert response.status_code == 404


def test_password_checkout_uses_owner_from_session_without_uid(login_client, db):
    provision(login_client, db)
    teacher = headers(login(login_client))
    response = login_client.post(
        "/checkout-requests",
        headers=teacher,
        json={"quantity": 1, "purpose": "Atividade individual"},
    )
    assert response.status_code == 201
    session = db.get(CheckoutSession, response.json()["session_id"])
    assert session.professor_id == professor_id(db)


def test_password_session_rejects_other_badge_before_effects(login_client, db):
    provision(login_client, db)
    teacher = headers(login(login_client))
    response = login_client.post(
        "/checkout-requests",
        headers=teacher,
        json={"badge_uid": OTHER_ACTIVE_BADGE, "quantity": 1, "purpose": "Atividade"},
    )
    assert response.status_code == 403
    assert db.scalar(select(CheckoutSession)) is None


def test_admin_still_needs_target_badge(login_client):
    response = login_client.post(
        "/checkout-requests",
        headers=admin(login_client),
        json={"quantity": 1, "purpose": "Atividade"},
    )
    assert response.status_code == 422


def test_password_session_cannot_read_or_return_another_professors_loan(login_client, db):
    provision(login_client, db)
    teacher = headers(login(login_client))
    owner = professor_id(db, OTHER_ACTIVE_BADGE)
    session = CheckoutSession(
        professor_id=owner,
        cabinet_id=db.scalar(select(Cabinet.id)),
        requested_quantity=1,
        purpose="Aula",
        status="OPEN",
    )
    db.add(session)
    db.commit()
    assert (
        login_client.get("/history", params={"professor_id": owner}, headers=teacher).status_code
        == 403
    )
    assert login_client.get("/history", headers=teacher).json()["total"] == 0
    assert (
        login_client.post(
            "/returns/reconcile",
            headers=teacher,
            json={"session_id": session.id, "event_id": "other-return-pwd"},
        ).status_code
        == 403
    )
    assert (
        login_client.post(
            "/returns/reconcile",
            headers=teacher,
            json={"session_id": session.id, "event_id": "manual-return-pwd", "present_tags": []},
        ).status_code
        == 403
    )


@pytest.mark.parametrize(
    "changes",
    [
        {"auth": "unknown"},
        {"revision": "old-revision"},
        {"revision": "não-válida"},
        {"exp": 1},
        {"role": "admin"},
    ],
)
def test_tampered_or_expired_claims_do_not_bypass_authorization(
    login_client, db, settings, changes
):
    provision(login_client, db)
    credential = db.get(ProfessorCredential, professor_id(db))
    claims = {
        "role": "professor",
        "sub": professor_id(db),
        "auth": "password",
        "revision": credential.revision,
        "exp": int(time.time()) + 60,
    }
    claims.update(changes)
    token = sign_claims(claims, settings)
    assert (
        login_client.get("/history", headers={"Authorization": "Bearer " + token}).status_code
        == 401
    )
