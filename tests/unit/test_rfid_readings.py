import json

import httpx
import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from armario_tablets.api.main import create_app
from armario_tablets.api.routes.rfid import get_rfid_sheet
from armario_tablets.config import get_settings
from armario_tablets.integrations.google_rfid_sheet import GoogleRfidSheet
from armario_tablets.integrations.google_sheets import READ_SCOPE, GoogleSheetsReader

PATH = "/admin/rfid/leituras"
HEADER = [" Data/Hora ", "UID", "Terminal", "Status"]


@pytest.fixture
def rfid_client(settings):
    settings.admin_password = SecretStr("fixture-admin-password")
    settings.admin_token_secret = SecretStr("fixture-signing-secret-32-bytes-long")
    app = create_app()
    app.dependency_overrides[get_settings] = lambda: settings
    with TestClient(app) as client:
        login = client.post(
            "/admin/login",
            json={"username": settings.admin_username, "password": "fixture-admin-password"},
        )
        assert login.status_code == 200
        yield client, {"Authorization": f"Bearer {login.json()['access_token']}"}


@pytest.fixture
def mock_sheet(settings, rfid_client, tmp_path):
    client, _ = rfid_client
    settings.rfid_sheets_enabled = True
    settings.rfid_sheets_spreadsheet_id = "fake-rfid-sheet-id-0000000000"
    settings.rfid_sheets_token_file = tmp_path / "token.json"
    settings.rfid_sheets_token_file.write_text(
        json.dumps(
            {
                "client_id": "fake-client",
                "client_secret": "fake-secret",
                "refresh_token": "fake-refresh",
                "scopes": [READ_SCOPE],
            }
        ),
        encoding="utf-8",
    )

    def configure(rows, *, status=200):
        def handle(request):
            if request.url.host == "oauth2.googleapis.com":
                assert request.method == "POST"
                return httpx.Response(200, json={"access_token": "fake-access"})
            assert request.url.host == "sheets.googleapis.com"
            assert request.method == "GET"
            assert request.headers["authorization"] == "Bearer fake-access"
            assert request.url.path.endswith("/values/'Leituras_RFID'!A1:D")
            assert request.url.params["valueRenderOption"] == "FORMATTED_VALUE"
            return httpx.Response(status, json={"values": rows, "message": "fake-secret"})

        reader = GoogleSheetsReader(
            settings.rfid_sheets_spreadsheet_id,
            settings.rfid_sheets_token_file,
            transport=httpx.MockTransport(handle),
        )
        client.app.dependency_overrides[get_rfid_sheet] = lambda: GoogleRfidSheet(settings, reader)

    return configure


def test_readings_show_last_nonempty_rows_and_preserve_uid_text(rfid_client, mock_sheet):
    client, auth = rfid_client
    mock_sheet(
        [HEADER, ["01/11/2026", "ABCD", "Carrinho", "RECEBIDO"], [], ["02/11/2026", "001234"], [""]]
    )
    response = client.get(PATH, params={"limite": 1}, headers=auth)
    assert response.status_code == 200
    assert response.headers["cache-control"] == "no-store"
    assert response.json() == {
        "leituras": [{"data/hora": "02/11/2026", "uid": "001234", "terminal": None, "status": None}]
    }
    assert [item["uid"] for item in client.get(PATH, headers=auth).json()["leituras"]] == [
        "001234",
        "ABCD",
    ]


@pytest.mark.parametrize("rows", [[], [HEADER], [HEADER, [], ["", "", "", ""]]])
def test_empty_rfid_sheet(rfid_client, mock_sheet, rows):
    client, auth = rfid_client
    mock_sheet(rows)
    assert client.get(PATH, headers=auth).json() == {"leituras": []}


@pytest.mark.parametrize("limit", [0, 101, "abc"])
def test_invalid_limit_is_rejected(rfid_client, limit):
    client, auth = rfid_client
    assert client.get(PATH, params={"limite": limit}, headers=auth).status_code == 422


def test_source_requires_admin_before_it_is_built(rfid_client):
    client, _ = rfid_client

    def forbidden():
        pytest.fail("A request without an admin session must not read RFID data")

    client.app.dependency_overrides[get_rfid_sheet] = forbidden
    assert client.get(PATH).status_code == 401
    assert client.get(PATH, headers={"Authorization": "Bearer invalid"}).status_code == 401


def test_rfid_integration_is_optional(rfid_client):
    client, auth = rfid_client
    response = client.get(PATH, headers=auth)
    assert response.status_code == 503
    assert response.json()["code"] == "RfidSourceUnconfiguredError"


@pytest.mark.parametrize(("rows", "status"), [([HEADER], 403), ([["wrong header"]], 200)])
def test_source_error_does_not_show_upstream_details(rfid_client, mock_sheet, rows, status):
    client, auth = rfid_client
    mock_sheet(rows, status=status)
    response = client.get(PATH, headers=auth)
    assert response.status_code == 502
    assert response.json()["code"] == "RfidSourceUnavailableError"
    assert "fake-secret" not in response.text
