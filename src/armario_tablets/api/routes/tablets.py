from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.schemas.tablet_schema import AvailabilityOut, TabletOut
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/tablets", tags=["tablets"])


@router.get("/available", response_model=AvailabilityOut)
def list_available(services: Services = Depends(get_services)) -> AvailabilityOut:
    return services.availability.snapshot()


@router.get("", response_model=list[TabletOut])
def list_tablets(status: str | None = None, services: Services = Depends(get_services)):
    return [TabletOut.from_model(t) for t in services.tablets.list_all(status)]
