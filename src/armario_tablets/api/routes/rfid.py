from fastapi import APIRouter, Depends, Query, Response

from armario_tablets.api.routes.admin import get_admin_session
from armario_tablets.config import Settings, get_settings
from armario_tablets.integrations.google_rfid_sheet import GoogleRfidSheet
from armario_tablets.integrations.google_sheets import GoogleSheetsReader
from armario_tablets.schemas.rfid_schema import RfidReadings

router = APIRouter(
    prefix="/admin/rfid",
    tags=["leituras RFID"],
    dependencies=[Depends(get_admin_session)],
)


def get_rfid_sheet(settings: Settings = Depends(get_settings)) -> GoogleRfidSheet:
    reader = GoogleSheetsReader(
        settings.rfid_sheets_spreadsheet_id, settings.rfid_sheets_token_file
    )
    return GoogleRfidSheet(settings, reader)


@router.get("/leituras", response_model=RfidReadings)
def list_recent_readings(
    response: Response,
    limite: int = Query(default=10, ge=1, le=100),
    source: GoogleRfidSheet = Depends(get_rfid_sheet),
) -> RfidReadings:
    response.headers["Cache-Control"] = "no-store"
    return RfidReadings(leituras=source.read_recent(limite))
