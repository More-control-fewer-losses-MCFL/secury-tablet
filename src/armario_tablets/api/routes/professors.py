from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.schemas.professor_schema import ProfessorOut
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/professors", tags=["professores"])


@router.get("/by-badge/{badge_uid}", response_model=ProfessorOut)
def get_by_badge(badge_uid: str, services: Services = Depends(get_services)) -> ProfessorOut:
    """Use só em rede local protegida. O UID não é gravado em logs."""
    return ProfessorOut.model_validate(services.badges.identify(badge_uid))
