from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.api.security import require_hardware_key
from armario_tablets.schemas.event_schema import EventOut, HardwareEventIn
from armario_tablets.services.factory import Services

router = APIRouter(
    prefix="/hardware", tags=["hardware"], dependencies=[Depends(require_hardware_key)]
)


@router.post("/events", response_model=EventOut)
def receive_event(event: HardwareEventIn, services: Services = Depends(get_services)) -> EventOut:
    """Recebe eventos do controlador. Idempotente pelo `event_id` (duplicado => duplicate=true)."""
    return services.events.handle(event)
