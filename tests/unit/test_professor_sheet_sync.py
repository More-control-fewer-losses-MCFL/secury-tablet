"""Import contracts, atomicity and authorization; only fictional records."""

import json
from types import SimpleNamespace

import httpx
import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import func, select

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.main import create_app
from armario_tablets.api.routes.professor_sync import get_professor_sheet
from armario_tablets.config import Settings, get_settings
from armario_tablets.exceptions import ProfessorImportInvalidError, ProfessorSourceUnavailableError
from armario_tablets.integrations.google_professor_sheet import (
    HEADERS,
    READ_SCOPE,
    GoogleProfessorSheet,
    parse_professors,
)
from armario_tablets.models import Professor
from armario_tablets.schemas.professor_sync_schema import ProfessorImport
from tests.factories import ACTIVE_BADGE

PATH = "/admin/professors/sync-google-sheets"


def record(registration="S-001", badge="CD000001", active=True):
    return ProfessorImport(
        registration=registration, name="Imported Test Teacher", badge_uid=badge, active=active
    )


@pytest.fixture
def sync_client(db, services, settings):
    settings.admin_password = SecretStr("sheets-test-password")
    settings.admin_token_secret = SecretStr("s" * 32)
    app = create_app()
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_services] = lambda: services
    app.dependency_overrides[get_settings] = lambda: settings
    with TestClient(app) as client:
        yield client


def admin(client):
    response = client.post(
        "/admin/login", json={"username": "admin", "password": "sheets-test-password"}
    )
    assert response.status_code == 200
    return {"Authorization": "Bearer " + response.json()["access_token"]}


def source(client, records):
    client.app.dependency_overrides[get_professor_sheet] = lambda: SimpleNamespace(
        read_professors=lambda: records
    )


def test_import_is_idempotent_and_preserves_absent_records(sync_client, db):
    headers = admin(sync_client)
    source(sync_client, [record()])
    before = db.scalar(select(func.count(Professor.id)))
    assert sync_client.post(PATH, headers=headers).json() == {
        "created": 1,
        "updated": 0,
        "unchanged": 0,
    }
    professor = db.scalar(select(Professor).where(Professor.registration == "S-001"))
    original_id = professor.id
    assert sync_client.post(PATH, headers=headers).json()["unchanged"] == 1
    assert db.scalar(select(func.count(Professor.id))) == before + 1
    assert professor.id == original_id
    source(sync_client, [])
    assert sync_client.post(PATH, headers=headers).json()["created"] == 0
    assert db.get(Professor, original_id).active


def test_sheet_import_can_login_only_as_teacher(sync_client):
    headers = admin(sync_client)
    source(sync_client, [record()])
    assert sync_client.post(PATH, headers=headers).status_code == 200
    assert sync_client.post("/auth/rfid", json={"badge_uid": "CD000001"}).status_code == 401
    assert sync_client.post("/terminal/authorize", headers=headers).status_code == 200
    response = sync_client.post("/auth/rfid", json={"badge_uid": "CD000001"})
    assert response.status_code == 200
    teacher = {"Authorization": "Bearer " + response.json()["access_token"]}
    assert sync_client.get("/tablets/available", headers=teacher).status_code == 200
    assert sync_client.get("/tablets", headers=teacher).status_code == 403
    assert sync_client.post(PATH, headers=teacher).status_code == 401


def test_deactivation_preserves_id_and_rejects_existing_session(sync_client, db):
    headers = admin(sync_client)
    sync_client.post("/terminal/authorize", headers=headers)
    response = sync_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE})
    teacher = {"Authorization": "Bearer " + response.json()["access_token"]}
    professor = db.scalar(select(Professor).where(Professor.registration == "T-1"))
    original_id = professor.id
    source(sync_client, [record("T-1", ACTIVE_BADGE, active=False)])
    assert sync_client.post(PATH, headers=headers).json()["updated"] == 1
    assert professor.id == original_id and not professor.active
    assert sync_client.get("/history", headers=teacher).status_code == 403
    assert sync_client.post("/auth/rfid", json={"badge_uid": ACTIVE_BADGE}).status_code == 403


def test_conflict_rolls_back_all_rows(sync_client, db):
    source(sync_client, [record(), record("CONFLICT", ACTIVE_BADGE)])
    response = sync_client.post(PATH, headers=admin(sync_client))
    assert response.status_code == 409
    assert db.scalar(select(Professor).where(Professor.registration == "S-001")) is None
    assert (
        db.scalar(select(Professor).where(Professor.badge_uid == ACTIVE_BADGE)).registration
        == "T-1"
    )


def test_anonymous_cannot_construct_source_or_services(sync_client):
    def forbidden():
        pytest.fail("Unauthorized caller constructed import dependencies")

    sync_client.app.dependency_overrides[get_professor_sheet] = forbidden
    sync_client.app.dependency_overrides[get_services] = forbidden
    assert sync_client.post(PATH).status_code == 401


def test_source_disabled_does_not_import(sync_client, db):
    count = db.scalar(select(func.count(Professor.id)))
    assert sync_client.post(PATH, headers=admin(sync_client)).status_code == 503
    assert db.scalar(select(func.count(Professor.id))) == count


@pytest.mark.parametrize(
    "rows",
    [
        [["Data/Hora", "UID", "Terminal", "Status"]],
        [HEADERS, ["S-1", "Test", "CD000001", "yes"]],
        [HEADERS, ["S-1", "Test", 1234, True]],
        [HEADERS, ["S-1", "Test", "CD000001"]],
        [HEADERS, ["S-1", "Test", "CD000001", True], ["s-1", "Other", "CD000002", True]],
        [HEADERS, ["S-1", "Test", "CD000001", True], ["S-2", "Other", "CD:00:00:01", True]],
    ],
)
def test_invalid_register_rejected_without_personal_data_in_error(rows):
    with pytest.raises(ProfessorImportInvalidError) as error:
        parse_professors(rows, 100)
    assert "CD000001" not in str(error.value)


def test_register_normalization_and_limit():
    rows = [HEADERS, [" S-1 ", " Test ", "cd:00:00:01", "TRUE"], []]
    parsed = parse_professors(rows, 10)
    assert parsed[0] == record("S-1").model_copy(update={"name": "Test"})
    with pytest.raises(ProfessorImportInvalidError):
        parse_professors(rows, 1)


def sheet_settings(settings, tmp_path):
    path = tmp_path / "token.json"
    path.write_text(
        json.dumps(
            {
                "client_id": "fake-client",
                "client_secret": "fake-secret",
                "refresh_token": "fake-refresh",
                "scopes": [READ_SCOPE],
            }
        )
    )
    settings.google_sheets_enabled = True
    settings.google_sheets_spreadsheet_id = "fake-sheet-id-00000000000000"
    settings.google_sheets_token_file = path
    return settings


def test_google_adapter_only_reads_bounded_register(settings, tmp_path):
    calls = []

    def handle(request):
        calls.append(request)
        if request.url.host == "oauth2.googleapis.com":
            assert request.method == "POST"
            return httpx.Response(200, json={"access_token": "fake-access"})
        assert request.method == "GET"
        assert request.headers["authorization"] == "Bearer fake-access"
        assert "fake-access" not in str(request.url)
        assert "D1002" in str(request.url)
        return httpx.Response(200, json={"values": [HEADERS, ["S-001", "Test", "CD000001", True]]})

    adapter = GoogleProfessorSheet(
        sheet_settings(settings, tmp_path), transport=httpx.MockTransport(handle)
    )
    assert len(adapter.read_professors()) == 1
    assert len(calls) == 2


@pytest.mark.parametrize("status", [401, 403, 429, 500])
def test_google_failures_are_redacted(settings, tmp_path, status):
    adapter = GoogleProfessorSheet(
        sheet_settings(settings, tmp_path),
        transport=httpx.MockTransport(lambda _: httpx.Response(status, text="fake-secret")),
    )
    with pytest.raises(ProfessorSourceUnavailableError) as error:
        adapter.read_professors()
    assert "fake-secret" not in str(error.value)


def test_broader_google_scope_is_not_accepted(settings, tmp_path):
    sheet_settings(settings, tmp_path)
    settings.google_sheets_token_file.write_text(json.dumps({"scopes": ["full-access"]}))

    def forbidden(_):
        pytest.fail("Broader credential must not be used")

    adapter = GoogleProfessorSheet(settings, transport=httpx.MockTransport(forbidden))
    with pytest.raises(ProfessorSourceUnavailableError):
        adapter.read_professors()


# --- Public link mode (gviz CSV export, no OAuth); fictional data only ---

SHEET_ID = "fake-sheet-id-00000000000000"
# gviz quotes every value, including booleans and numbers stored as text.
GVIZ_CSV = (
    '"registration","name","badge_uid","active"\n'
    '"0042","Ana Test","cd:00:00:01","TRUE"\n'
    '"S-002","Bruno Test","CD000002","false"\n'
    '"","","",""\n'
    "\n"
)


def public_settings(settings, tab="Professores"):
    settings.google_sheets_enabled = True
    settings.google_sheets_public_csv = True
    settings.google_sheets_spreadsheet_id = SHEET_ID
    settings.google_sheets_professors_tab = tab
    settings.google_sheets_token_file = None
    return settings


def csv_reply(text=GVIZ_CSV, content_type="text/csv; charset=utf-8", status=200):
    return httpx.Response(status, text=text, headers={"content-type": content_type})


def public_adapter(settings, handler):
    return GoogleProfessorSheet(public_settings(settings), transport=httpx.MockTransport(handler))


def test_public_csv_reads_bounded_tab_without_token_or_auth(settings):
    calls = []

    def handle(request):
        calls.append(request)
        return csv_reply()

    adapter = GoogleProfessorSheet(
        public_settings(settings, tab="Professores 2026"), transport=httpx.MockTransport(handle)
    )
    records = adapter.read_professors()

    assert len(calls) == 1
    request = calls[0]
    assert request.method == "GET"
    assert request.url.scheme == "https" and request.url.host == "docs.google.com"
    assert request.url.path == f"/spreadsheets/d/{SHEET_ID}/gviz/tq"
    assert request.url.params["tqx"] == "out:csv"
    assert request.url.params["sheet"] == "Professores 2026"
    assert "Professores%202026" in str(request.url)
    assert request.url.params["range"] == "A1:D1002"
    assert "authorization" not in request.headers
    assert [(r.registration, r.badge_uid, r.active) for r in records] == [
        ("0042", "CD000001", True),
        ("S-002", "CD000002", False),
    ]


def test_public_csv_handles_bom_and_crlf(settings):
    text = "﻿" + GVIZ_CSV.replace("\n", "\r\n")
    adapter = public_adapter(settings, lambda _: csv_reply(text))
    assert len(adapter.read_professors()) == 2


def test_public_csv_imports_like_oauth_mode(sync_client, db, settings):
    headers = admin(sync_client)
    reply = {"text": GVIZ_CSV}
    adapter = public_adapter(settings, lambda _: csv_reply(reply["text"]))
    sync_client.app.dependency_overrides[get_professor_sheet] = lambda: adapter

    assert sync_client.post(PATH, headers=headers).json() == {
        "created": 2,
        "updated": 0,
        "unchanged": 0,
    }
    ana = db.scalar(select(Professor).where(Professor.registration == "0042"))
    assert ana.badge_uid == "CD000001" and ana.active
    assert sync_client.post(PATH, headers=headers).json() == {
        "created": 0,
        "updated": 0,
        "unchanged": 2,
    }
    reply["text"] = GVIZ_CSV.replace('"Ana Test"', '"Ana Renamed Test"')
    assert sync_client.post(PATH, headers=headers).json() == {
        "created": 0,
        "updated": 1,
        "unchanged": 1,
    }


@pytest.mark.parametrize(
    "reply",
    [
        httpx.Response(302, headers={"location": "https://accounts.google.com/ServiceLogin"}),
        httpx.Response(307, headers={"location": "https://docs.google.com/other"}),
        csv_reply(status=401),
        csv_reply(status=403),
        csv_reply(status=404),
        csv_reply(status=500),
        csv_reply("<!DOCTYPE html><html>Fazer login</html>", "text/html; charset=utf-8"),
        csv_reply("<!DOCTYPE html><html>Fazer login</html>"),
        csv_reply("registration,name\n", "application/json"),
    ],
)
def test_public_csv_unavailable_when_not_shared_and_redacted(settings, reply):
    calls = []

    def handle(request):
        calls.append(request)
        return reply

    adapter = public_adapter(settings, handle)
    with pytest.raises(ProfessorSourceUnavailableError) as error:
        adapter.read_professors()
    assert len(calls) == 1, "redirects must not be followed"
    message = str(error.value)
    for leaked in (SHEET_ID, "docs.google.com", "gviz", "CD000001", "Fazer login"):
        assert leaked not in message
    assert "link" in message


def test_public_csv_unavailable_maps_to_503(sync_client, settings):
    adapter = public_adapter(settings, lambda _: csv_reply(status=403))
    sync_client.app.dependency_overrides[get_professor_sheet] = lambda: adapter
    response = sync_client.post(PATH, headers=admin(sync_client))
    assert response.status_code == 503
    assert SHEET_ID not in response.text


@pytest.mark.parametrize(
    "text",
    [
        '"Data/Hora","UID","Terminal","Status"\n"x","CD000001","T1","OK"\n',
        '"registration","name","badge_uid","active","extra"\n',
        '"registration","name","badge_uid","active"\n"S-1","Test","CD000001","yes"\n',
        '"registration","name","badge_uid","active"\n"S-1","Test","CD000001"\n',
        "",
    ],
)
def test_public_csv_invalid_register_is_rejected(settings, text):
    adapter = public_adapter(settings, lambda _: csv_reply(text))
    with pytest.raises(ProfessorImportInvalidError) as error:
        adapter.read_professors()
    assert "CD000001" not in str(error.value)


def test_public_csv_invalid_register_maps_to_422_without_writes(sync_client, db, settings):
    count = db.scalar(select(func.count(Professor.id)))
    text = GVIZ_CSV.replace('"registration"', '"matricula"')
    adapter = public_adapter(settings, lambda _: csv_reply(text))
    sync_client.app.dependency_overrides[get_professor_sheet] = lambda: adapter
    assert sync_client.post(PATH, headers=admin(sync_client)).status_code == 422
    assert db.scalar(select(func.count(Professor.id))) == count


def test_public_csv_respects_row_limit(settings):
    settings.google_sheets_max_professors = 1
    adapter = public_adapter(settings, lambda _: csv_reply())
    with pytest.raises(ProfessorImportInvalidError):
        adapter.read_professors()


@pytest.mark.parametrize("change", ["disabled", "bad_id"])
def test_public_csv_requires_enabled_flag_and_valid_id(settings, change):
    public_settings(settings)
    if change == "disabled":
        settings.google_sheets_enabled = False
    else:
        settings.google_sheets_spreadsheet_id = "../not-an-id"

    def forbidden(_):
        pytest.fail("Misconfigured source must not reach the network")

    adapter = GoogleProfessorSheet(settings, transport=httpx.MockTransport(forbidden))
    with pytest.raises(ProfessorSourceUnavailableError):
        adapter.read_professors()


def test_oauth_mode_still_requires_token_file_and_ignores_public_url(settings):
    public_settings(settings)
    settings.google_sheets_public_csv = False

    def forbidden(_):
        pytest.fail("OAuth mode without token must not call Google")

    adapter = GoogleProfessorSheet(settings, transport=httpx.MockTransport(forbidden))
    with pytest.raises(ProfessorSourceUnavailableError):
        adapter.read_professors()


def test_public_csv_defaults_to_disabled():
    assert Settings(_env_file=None).google_sheets_public_csv is False
