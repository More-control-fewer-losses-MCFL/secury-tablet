from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.operational_auth import Principal, require_principal
from armario_tablets.models import CheckoutSession
from armario_tablets.schemas.checkout_schema import CheckoutOut, ReconcileIn
from armario_tablets.services.factory import Services

router = APIRouter(prefix="/returns", tags=["devolução"])


def authorize_return(
    body: ReconcileIn,
    principal: Principal = Depends(require_principal),
    db: Session = Depends(get_db),
) -> None:
    if principal.role == "admin":
        return
    if body.present_tags is not None:
        raise HTTPException(403, "Inventário manual exige administração.")
    session = db.get(CheckoutSession, body.session_id)
    if session is None:
        raise HTTPException(404, "Solicitação não encontrada.")
    if session.professor_id != principal.professor_id:
        raise HTTPException(403, "Não é permitido conciliar a sessão de outro professor.")


@router.post("/reconcile", response_model=CheckoutOut, dependencies=[Depends(authorize_return)])
def reconcile_return(body: ReconcileIn, services: Services = Depends(get_services)) -> CheckoutOut:
    """Concilia a devolução tablet a tablet. Repetir o mesmo event_id não duplica nada."""
    present = set(body.present_tags) if body.present_tags is not None else None
    return services.returns.reconcile(body.session_id, body.event_id, present, source="api")
