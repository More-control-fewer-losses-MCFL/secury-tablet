"""Only administrators may import the authorized professor register."""

from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.api.routes.admin import get_admin_session
from armario_tablets.config import Settings, get_settings
from armario_tablets.integrations.google_professor_sheet import GoogleProfessorSheet
from armario_tablets.schemas.professor_sync_schema import ProfessorSyncResult
from armario_tablets.services.factory import Services

router = APIRouter(
    prefix="/admin/professors",
    tags=["cadastro Google Sheets"],
    dependencies=[Depends(get_admin_session)],
)


def get_professor_sheet(settings: Settings = Depends(get_settings)) -> GoogleProfessorSheet:
    return GoogleProfessorSheet(settings)


@router.post("/sync-google-sheets", response_model=ProfessorSyncResult)
def sync_professors(
    source: GoogleProfessorSheet = Depends(get_professor_sheet),
    services: Services = Depends(get_services),
) -> ProfessorSyncResult:
    return services.professor_sync.sync(source.read_professors())
