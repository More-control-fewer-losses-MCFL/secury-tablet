from fastapi import APIRouter, Depends, Header

from armario_tablets.api.deps import get_services
from armario_tablets.api.routes.admin import get_admin_session
from armario_tablets.config import Settings, get_settings
from armario_tablets.schemas.checkout_schema import CheckoutOut, ReconcileIn
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/returns", tags=["devolução"])


def authorize_inventory_override(
    body: ReconcileIn,
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> None:
    """Only an administrator may replace the physical reader's inventory."""
    if body.present_tags is not None:
        get_admin_session(authorization=authorization, settings=settings)


@router.post(
    "/reconcile",
    response_model=CheckoutOut,
    dependencies=[Depends(authorize_inventory_override)],
)
def reconcile_return(body: ReconcileIn, services: Services = Depends(get_services)) -> CheckoutOut:
    """Concilia a devolução tablet a tablet. Repetir o mesmo event_id não duplica nada."""
    present = set(body.present_tags) if body.present_tags is not None else None
    return services.returns.reconcile(body.session_id, body.event_id, present, source="api")
