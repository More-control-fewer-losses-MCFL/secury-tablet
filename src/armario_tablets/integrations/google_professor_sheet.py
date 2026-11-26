"""Read-only Google Sheets adapter. Never grants a session or touches hardware."""

import csv
import io
import json
import re
from urllib.parse import quote

import httpx
from pydantic import ValidationError

from armario_tablets.config import Settings
from armario_tablets.exceptions import (
    InvalidUidError,
    ProfessorImportInvalidError,
    ProfessorSourceUnavailableError,
)
from armario_tablets.schemas.professor_sync_schema import ProfessorImport

READ_SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"
HEADERS = ["registration", "name", "badge_uid", "active"]
PUBLIC_CSV_HOST = "docs.google.com"
BOM = chr(0xFEFF)
OAUTH_UNAVAILABLE = "Nao foi possivel consultar o cadastro Google; verifique aba e credenciais."
PUBLIC_UNAVAILABLE = (
    "Nao foi possivel ler a planilha pelo link publico; confirme o compartilhamento "
    "'qualquer pessoa com o link pode ver' e o nome da aba."
)


def parse_professors(values: list, maximum: int) -> list[ProfessorImport]:
    if not values or values[0] != HEADERS:
        raise ProfessorImportInvalidError(
            "Cabecalho esperado: registration, name, badge_uid, active."
        )
    if len(values) > maximum + 1:
        raise ProfessorImportInvalidError("Limite de linhas excedido; nada foi importado.")
    records = []
    registrations: set[str] = set()
    badges: set[str] = set()
    for row_number, row in enumerate(values[1:], start=2):
        if not isinstance(row, list):
            raise ProfessorImportInvalidError(f"Linha {row_number} invalida.")
        if not row or all(value in ("", None) for value in row):
            continue
        if len(row) != 4:
            raise ProfessorImportInvalidError(f"Linha {row_number}: quatro campos obrigatorios.")
        active = row[3]
        if isinstance(active, str):
            active = {"TRUE": True, "FALSE": False}.get(active.strip().upper(), active)
        try:
            record = ProfessorImport(
                registration=row[0], name=row[1], badge_uid=row[2], active=active
            )
        except (ValidationError, InvalidUidError):
            raise ProfessorImportInvalidError(f"Linha {row_number}: dados invalidos.") from None
        if record.registration.casefold() in registrations or record.badge_uid in badges:
            raise ProfessorImportInvalidError(f"Linha {row_number}: cadastro duplicado.")
        registrations.add(record.registration.casefold())
        badges.add(record.badge_uid)
        records.append(record)
    return records


class GoogleProfessorSheet:
    def __init__(self, settings: Settings, *, transport=None):
        self.settings = settings
        self.transport = transport

    def read_professors(self) -> list[ProfessorImport]:
        settings = self.settings
        public = settings.google_sheets_public_csv
        if (
            not settings.google_sheets_enabled
            or (not public and not settings.google_sheets_token_file)
            or not re.fullmatch(r"[A-Za-z0-9_-]{20,200}", settings.google_sheets_spreadsheet_id)
        ):
            raise ProfessorSourceUnavailableError("Integracao Google Sheets nao configurada.")
        try:
            values = self._read_public_csv() if public else self._read_oauth()
        except (
            httpx.HTTPError,
            OSError,
            ValueError,
            KeyError,
            TypeError,
            AttributeError,
            csv.Error,
        ):
            raise ProfessorSourceUnavailableError(
                PUBLIC_UNAVAILABLE if public else OAUTH_UNAVAILABLE
            ) from None
        return parse_professors(values, settings.google_sheets_max_professors)

    def _client(self) -> httpx.Client:
        return httpx.Client(timeout=10, follow_redirects=False, transport=self.transport)

    def _read_oauth(self) -> list:
        settings = self.settings
        credentials = json.loads(settings.google_sheets_token_file.read_text(encoding="utf-8"))
        if credentials.get("scopes") != [READ_SCOPE]:
            raise ValueError("Read-only authorization required")
        with self._client() as client:
            response = client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": credentials["refresh_token"],
                    "client_id": credentials["client_id"],
                    "client_secret": credentials["client_secret"],
                },
            )
            response.raise_for_status()
            access_token = response.json()["access_token"]
            tab = settings.google_sheets_professors_tab.replace("'", "''")
            cell_range = quote(f"'{tab}'!A1:D{settings.google_sheets_max_professors + 2}", safe="")
            response = client.get(
                "https://sheets.googleapis.com/v4/spreadsheets/"
                f"{settings.google_sheets_spreadsheet_id}/values/{cell_range}",
                headers={"Authorization": f"Bearer {access_token}"},
                params={"valueRenderOption": "UNFORMATTED_VALUE", "majorDimension": "ROWS"},
            )
            response.raise_for_status()
            values = response.json().get("values", [])
            if not isinstance(values, list):
                raise ValueError("Invalid response")
        return values

    def _read_public_csv(self) -> list[list[str]]:
        """Read the tab through the link-shared CSV export; no credentials involved.

        A redirect (usually to the Google login) or any status other than 200 means
        the sheet is not shared by link. An HTML body is the login page, not data.
        """
        settings = self.settings
        query = (
            f"tqx=out:csv&headers=1&sheet={quote(settings.google_sheets_professors_tab, safe='')}"
            f"&range=A1:D{settings.google_sheets_max_professors + 2}"
        )
        url = (
            f"https://{PUBLIC_CSV_HOST}/spreadsheets/d/"
            f"{settings.google_sheets_spreadsheet_id}/gviz/tq?{query}"
        )
        with self._client() as client:
            response = client.get(url)
        if response.status_code != 200:
            raise ValueError("Sheet not shared by link")
        content_type = response.headers.get("content-type", "").split(";")[0].strip().lower()
        text = response.text.removeprefix(BOM)
        if content_type != "text/csv" or text.lstrip().startswith("<"):
            raise ValueError("Not a CSV export")
        return list(csv.reader(io.StringIO(text, newline="")))
