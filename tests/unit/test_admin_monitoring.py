"""Segurança e métricas da central de ocorrências (sem hardware real)."""

from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import select

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.main import create_app
from armario_tablets.config import get_settings
from armario_tablets.models import Cabinet, CheckoutSession, Event, Professor, Tablet
from tests.factories import ACTIVE_BADGE


@pytest.fixture
def monitor_client(db, services, settings):
    settings.admin_password = SecretStr("test-admin-monitoring-password")
    settings.admin_token_secret = SecretStr("m" * 32)
    app = create_app()
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_services] = lambda: services
    with TestClient(app) as client:
        yield client


def admin_headers(client):
    response = client.post(
        "/admin/login",
        json={"username": "admin", "password": "test-admin-monitoring-password"},
    )
    assert response.status_code == 200
    return {"Authorization": "Bearer " + response.json()["access_token"]}


def test_monitoring_endpoints_reject_anonymous_requests(monitor_client):
    assert monitor_client.get("/admin/overview").status_code == 401
    assert monitor_client.get("/admin/alerts").status_code == 401


def test_teacher_cannot_read_admin_monitoring(monitor_client):
    admin = admin_headers(monitor_client)
    assert monitor_client.post("/terminal/authorize", headers=admin).status_code == 200
    teacher = monitor_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE})
    assert teacher.status_code == 200
    headers = {"Authorization": "Bearer " + teacher.json()["access_token"]}
    assert monitor_client.get("/admin/overview", headers=headers).status_code == 401
    assert monitor_client.get("/admin/alerts", headers=headers).status_code == 401


def test_dashboard_has_real_counts_and_no_false_alerts(monitor_client):
    response = monitor_client.get("/admin/overview", headers=admin_headers(monitor_client))
    assert response.status_code == 200
    body = response.json()
    assert body["inventory"] == {
        "total": 5,
        "available": 5,
        "checked_out": 0,
        "maintenance": 0,
    }
    assert body["sessions"] == {"open": 0, "divergent": 0, "in_flight": 0}
    assert body["alert_events_total"] == 0
    assert body["recent_alerts"] == []


def test_events_are_persisted_filtered_ordered_and_redacted(monitor_client, db):
    cabinet = db.scalar(select(Cabinet))
    now = datetime(2026, 11, 5, 16, 0, tzinfo=UTC)
    for index, event_type in enumerate(
        ("LOCK_ERROR", "DOOR_OPENED", "READER_ERROR", "RETURN_DIVERGENCE")
    ):
        db.add(
            Event(
                event_id=f"monitor-event-{index:03d}",
                cabinet_id=cabinet.id,
                type=event_type,
                source="hardware",
                occurred_at=now + timedelta(minutes=index),
                received_at=now + timedelta(minutes=index),
                details={"badge_uid": "CONFIDENTIAL-BADGE", "present_tags": ["SECRET-TAG"]},
            )
        )
    db.commit()

    admin = admin_headers(monitor_client)
    overview = monitor_client.get("/admin/overview", headers=admin)
    assert overview.status_code == 200
    body = overview.json()
    assert body["alert_events_total"] == 3  # DOOR_OPENED não é incidente isolado
    events = body["recent_alerts"]
    assert len(events) == 3
    assert events[0]["type"] == "RETURN_DIVERGENCE"
    assert events[1]["type"] == "READER_ERROR"
    assert events[2]["type"] == "LOCK_ERROR"
    assert events[2]["severity"] == "high"
    assert "CONFIDENTIAL" not in overview.text
    assert "SECRET-TAG" not in overview.text
    assert "details" not in events[0]
    limited_alerts = monitor_client.get("/admin/alerts", headers=admin, params={"limit": 2})
    invalid_limit = monitor_client.get("/admin/alerts", headers=admin, params={"limit": 51})
    assert limited_alerts.json() == events[:2]
    assert invalid_limit.status_code == 422


@pytest.mark.parametrize("path", ["/admin/overview", "/admin/alerts"])
def test_monitoring_rejects_teacher_before_services(monitor_client, path):
    admin = admin_headers(monitor_client)
    monitor_client.post("/terminal/authorize", headers=admin)
    teacher = monitor_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE})

    def forbidden():
        pytest.fail("Unauthorized monitoring constructed services")

    monitor_client.app.dependency_overrides[get_services] = forbidden
    headers = {"Authorization": "Bearer " + teacher.json()["access_token"]}
    assert monitor_client.get(path, headers=headers).status_code == 401


def test_monitoring_counts_all_session_states(monitor_client, db):
    cabinet = db.scalar(select(Cabinet))
    professor = db.scalar(select(Professor))
    tablets = list(db.scalars(select(Tablet).order_by(Tablet.id)))
    tablets[0].status = "CHECKED_OUT"
    tablets[1].status = "MAINTENANCE"
    for state in ("OPEN", "DIVERGENT", "PENDING", "UNLOCKED", "COMPLETED", "CANCELLED", "FAILED"):
        db.add(
            CheckoutSession(
                professor_id=professor.id,
                cabinet_id=cabinet.id,
                requested_quantity=1,
                purpose="Monitoring test",
                status=state,
            )
        )
    db.commit()
    response = monitor_client.get("/admin/overview", headers=admin_headers(monitor_client))
    assert response.status_code == 200
    assert response.json()["inventory"] == {
        "total": 5,
        "available": 3,
        "checked_out": 1,
        "maintenance": 1,
    }
    assert response.json()["sessions"] == {"open": 1, "divergent": 1, "in_flight": 2}


def test_alerts_have_stable_order_and_overview_is_bounded(monitor_client, db):
    cabinet = db.scalar(select(Cabinet))
    now = datetime(2026, 11, 5, 16, 0, tzinfo=UTC)
    for index in range(7):
        db.add(
            Event(
                event_id=f"monitor-tied-{index:03d}",
                cabinet_id=cabinet.id,
                type="EXTRA_WITHDRAWAL",
                source="hardware",
                occurred_at=now,
                received_at=now,
                details={},
            )
        )
        db.flush()
    db.commit()
    headers = admin_headers(monitor_client)
    overview = monitor_client.get("/admin/overview", headers=headers).json()
    alerts = monitor_client.get("/admin/alerts", headers=headers).json()
    assert overview["alert_events_total"] == 7
    assert len(overview["recent_alerts"]) == 5
    assert overview["recent_alerts"] == alerts[:5]
    assert [item["event_id"] for item in alerts] == [
        f"monitor-tied-{index:03d}" for index in reversed(range(7))
    ]
    assert monitor_client.get("/admin/alerts?limit=0", headers=headers).status_code == 422
