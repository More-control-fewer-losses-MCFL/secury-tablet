"""Recent RFID readings from the cart's Google Sheets tab."""

from armario_tablets.config import Settings
from armario_tablets.exceptions import RfidSourceUnavailableError, RfidSourceUnconfiguredError
from armario_tablets.integrations.google_sheets import (
    GoogleSheetsReader,
    GoogleSheetsUnavailableError,
)
from armario_tablets.schemas.rfid_schema import RfidReading

HEADERS = ("data/hora", "uid", "terminal", "status")


class GoogleRfidSheet:
    def __init__(self, settings: Settings, reader: GoogleSheetsReader):
        self.settings = settings
        self.reader = reader

    def read_recent(self, limit: int) -> list[RfidReading]:
        settings = self.settings
        if (
            not settings.rfid_sheets_enabled
            or not settings.rfid_sheets_spreadsheet_id
            or not settings.rfid_sheets_tab.strip()
            or not settings.rfid_sheets_token_file
        ):
            raise RfidSourceUnconfiguredError("Consulta RFID não configurada no servidor.")
        try:
            rows = self.reader.read_rows(settings.rfid_sheets_tab, "A1:D", render="FORMATTED_VALUE")
        except GoogleSheetsUnavailableError:
            raise RfidSourceUnavailableError(
                "Não foi possível consultar a planilha RFID."
            ) from None

        if not rows:
            return []
        header = rows[0]
        if (
            not isinstance(header, list)
            or tuple(str(cell).strip().lower() for cell in header) != HEADERS
        ):
            raise RfidSourceUnavailableError("Cabeçalho da planilha RFID inválido.")

        readings = []
        for index in range(len(rows) - 1, 0, -1):
            row = rows[index]
            if not isinstance(row, list):
                raise RfidSourceUnavailableError("A planilha RFID devolveu uma linha inválida.")
            if all(cell in ("", None) for cell in row):
                continue
            fields = {
                name: None if cell is None else str(cell)
                for name, cell in zip(HEADERS, row, strict=False)
            }
            readings.append(RfidReading.model_validate(fields))
            if len(readings) == limit:
                break
        return readings
