"""Read-only monitoring requiring an administrator session."""

from fastapi import APIRouter, Depends, Query

from armario_tablets.api.deps import get_services
from armario_tablets.api.routes.admin import get_admin_session
from armario_tablets.schemas.monitoring_schema import AdminOverview, AlertRecord
from armario_tablets.services.factory import Services

router = APIRouter(
    prefix="/admin",
    tags=["monitoramento administrativo"],
    dependencies=[Depends(get_admin_session)],
)


@router.get("/alerts", response_model=list[AlertRecord])
def list_alert_events(
    limit: int = Query(default=30, ge=1, le=50),
    services: Services = Depends(get_services),
) -> list[AlertRecord]:
    return services.monitoring.list_alerts(limit)


@router.get("/overview", response_model=AdminOverview)
def read_admin_overview(services: Services = Depends(get_services)) -> AdminOverview:
    return services.monitoring.overview()
