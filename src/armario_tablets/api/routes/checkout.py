from datetime import datetime

from fastapi import APIRouter, Depends, Query

from armario_tablets.api.deps import get_services
from armario_tablets.config import Settings, get_settings
from armario_tablets.schemas.checkout_schema import CheckoutOut, CheckoutRequestIn, HistoryPage
from armario_tablets.services.factory import Services

router = APIRouter(tags=["retirada"])


@router.post("/checkout-requests", response_model=CheckoutOut, status_code=201)
def create_checkout_request(
    body: CheckoutRequestIn,
    services: Services = Depends(get_services),
    settings: Settings = Depends(get_settings),
) -> CheckoutOut:
    """Valida, cria a solicitação e destrava o armário (após confirmação da fechadura).

    Os tablets só serão marcados como retirados quando o inventário for confirmado
    via POST /hardware/events (INVENTORY_AFTER_CHECKOUT).
    """
    return services.checkout.request_checkout(
        body.badge_uid, body.quantity, body.purpose, body.class_name, settings.cabinet_code
    )


@router.get("/history", response_model=HistoryPage)
def get_history(
    professor_id: int | None = None,
    status: str | None = None,
    since: datetime | None = None,
    until: datetime | None = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    services: Services = Depends(get_services),
) -> HistoryPage:
    return services.history.page(
        professor_id=professor_id,
        status=status,
        since=since,
        until=until,
        limit=limit,
        offset=offset,
    )
