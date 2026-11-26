"""Read-only access to Google Sheets using an offline OAuth grant."""

import json
import re
from pathlib import Path
from urllib.parse import quote

import httpx

READ_SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"


class GoogleSheetsUnavailableError(Exception):
    """The sheet or its read-only credentials could not be used."""


class GoogleSheetsReader:
    def __init__(
        self,
        spreadsheet_id: str,
        token_file: Path | None,
        *,
        transport: httpx.BaseTransport | None = None,
    ):
        self.spreadsheet_id = spreadsheet_id
        self.token_file = token_file
        self.transport = transport

    def read_rows(self, tab: str, cells: str, *, render: str) -> list:
        if not self.token_file or not re.fullmatch(r"[A-Za-z0-9_-]{20,200}", self.spreadsheet_id):
            raise GoogleSheetsUnavailableError

        try:
            credentials = json.loads(self.token_file.read_text(encoding="utf-8"))
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
                quoted_tab = tab.replace("'", "''")
                cell_range = quote(f"'{quoted_tab}'!{cells}", safe="")
                response = client.get(
                    "https://sheets.googleapis.com/v4/spreadsheets/"
                    f"{self.spreadsheet_id}/values/{cell_range}",
                    headers={"Authorization": f"Bearer {access_token}"},
                    params={"valueRenderOption": render, "majorDimension": "ROWS"},
                )
                response.raise_for_status()
                values = response.json().get("values", [])
                if not isinstance(values, list):
                    raise ValueError("Invalid response")
        except (httpx.HTTPError, OSError, ValueError, KeyError, TypeError, AttributeError):
            raise GoogleSheetsUnavailableError from None
        return values
