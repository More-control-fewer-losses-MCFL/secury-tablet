"""Read-only Google Sheets adapter. Never grants a session or touches hardware."""

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
        if (
            not settings.google_sheets_enabled
            or not settings.google_sheets_token_file
            or not re.fullmatch(r"[A-Za-z0-9_-]{20,200}", settings.google_sheets_spreadsheet_id)
        ):
            raise ProfessorSourceUnavailableError("Integracao Google Sheets nao configurada.")
        try:
            credentials = json.loads(settings.google_sheets_token_file.read_text(encoding="utf-8"))
            if credentials.get("scopes") != [READ_SCOPE]:
                raise ValueError("Read-only authorization required")
            with httpx.Client(
                timeout=10, follow_redirects=False, transport=self.transport
            ) as client:
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
                cell_range = quote(
                    f"'{tab}'!A1:D{settings.google_sheets_max_professors + 2}", safe=""
                )
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
        except (httpx.HTTPError, OSError, ValueError, KeyError, TypeError, AttributeError):
            raise ProfessorSourceUnavailableError(
                "Nao foi possivel consultar o cadastro Google; verifique aba e credenciais."
            ) from None
        return parse_professors(values, settings.google_sheets_max_professors)
