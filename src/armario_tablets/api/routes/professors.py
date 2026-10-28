from fastapi import APIRouter, Depends, HTTPException

from armario_tablets.api.deps import get_services
from armario_tablets.api.operational_auth import Principal, require_principal
from armario_tablets.schemas.professor_schema import ProfessorOut
from armario_tablets.services.factory import Services

router = APIRouter(
    prefix="/professors", tags=["professores"], dependencies=[Depends(require_principal)]
)


@router.get("/by-badge/{badge_uid}", response_model=ProfessorOut)
def get_by_badge(
    badge_uid: str,
    principal: Principal = Depends(require_principal),
    services: Services = Depends(get_services),
) -> ProfessorOut:
    """Use só em rede local protegida. O UID não é gravado em logs."""
    if principal.role != "admin" and badge_uid.upper() != principal.badge_uid:
        raise HTTPException(403, "Cadastro de outro professor indisponível.")
    return ProfessorOut.model_validate(services.badges.identify(badge_uid))
