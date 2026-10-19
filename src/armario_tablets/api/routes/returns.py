from fastapi import APIRouter, Depends

from armario_tablets.api.deps import get_services
from armario_tablets.schemas.checkout_schema import CheckoutOut, ReconcileIn
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/returns", tags=["devolução"])


@router.post("/reconcile", response_model=CheckoutOut)
def reconcile_return(body: ReconcileIn, services: Services = Depends(get_services)) -> CheckoutOut:
    """Concilia a devolução tablet a tablet. Repetir o mesmo event_id não duplica nada."""
    present = set(body.present_tags) if body.present_tags is not None else None
    return services.returns.reconcile(body.session_id, body.event_id, present, source="api")
