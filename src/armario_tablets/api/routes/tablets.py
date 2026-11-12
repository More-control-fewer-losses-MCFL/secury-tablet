from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.api.operational_auth import Principal, require_admin, require_principal
from armario_tablets.schemas.tablet_schema import AvailabilityOut, TabletOut
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/tablets", tags=["tablets"], dependencies=[Depends(require_principal)])


@router.get("/available", response_model=AvailabilityOut)
def list_available(
    principal: Principal = Depends(require_principal),
    services: Services = Depends(get_services),
) -> AvailabilityOut:
    return services.availability.snapshot(include_tablets=principal.role == "admin")


@router.get("", response_model=list[TabletOut], dependencies=[Depends(require_admin)])
def list_tablets(status: str | None = None, services: Services = Depends(get_services)):
    return [TabletOut.from_model(t) for t in services.tablets.list_all(status)]
