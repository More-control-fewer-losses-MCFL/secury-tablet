"""Read-only Google Sheets adapter. Never grants a session or touches hardware."""

from pydantic import ValidationError

from armario_tablets.config import Settings
from armario_tablets.exceptions import (
    InvalidUidError,
    ProfessorImportInvalidError,
    ProfessorSourceUnavailableError,
)
from armario_tablets.integrations.google_sheets import (
    GoogleSheetsReader,
    GoogleSheetsUnavailableError,
)
from armario_tablets.schemas.professor_sync_schema import ProfessorImport

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
        if not settings.google_sheets_enabled or not settings.google_sheets_token_file:
            raise ProfessorSourceUnavailableError("Integracao Google Sheets nao configurada.")
        reader = GoogleSheetsReader(
            settings.google_sheets_spreadsheet_id,
            settings.google_sheets_token_file,
            transport=self.transport,
        )
        try:
            values = reader.read_rows(
                settings.google_sheets_professors_tab,
                f"A1:D{settings.google_sheets_max_professors + 2}",
                render="UNFORMATTED_VALUE",
            )
        except GoogleSheetsUnavailableError:
            raise ProfessorSourceUnavailableError(
                "Nao foi possivel consultar o cadastro Google; verifique aba e credenciais."
            ) from None
        return parse_professors(values, settings.google_sheets_max_professors)
