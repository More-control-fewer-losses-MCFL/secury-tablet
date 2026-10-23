import logging
from datetime import datetime

from sqlalchemy.orm import Session

from armario_tablets.database.session import unit_of_work
from armario_tablets.exceptions import InvalidSessionStateError, ReaderError, SessionNotFoundError
from armario_tablets.models import ItemStatus, SessionStatus, TabletStatus
from armario_tablets.repositories.checkout_repository import CheckoutRepository
from armario_tablets.repositories.event_repository import EventRepository
from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.schemas.checkout_schema import CheckoutOut
from armario_tablets.schemas.event_schema import EventType
from armario_tablets.services.cabinet_service import CabinetService
from armario_tablets.services.checkout_service import build_checkout_out
from armario_tablets.services.inventory_service import InventoryService
from armario_tablets.utils.datetime_utils import utcnow

logger = logging.getLogger(__name__)


class ReturnService:
    """Conciliação da devolução, tablet a tablet."""

    def __init__(
        self,
        db: Session,
        cabinets: CabinetService,
        checkouts: CheckoutRepository,
        tablets: TabletRepository,
        events: EventRepository,
        inventory: InventoryService,
    ) -> None:
        self._db = db
        self._cabinets = cabinets
        self._checkouts = checkouts
        self._tablets = tablets
        self._events = events
        self._inventory = inventory

    def pending_returns(self) -> list[CheckoutOut]:
        """Solicitações com tablets ainda fora do armário (para a tela de devolução)."""
        sessions = self._checkouts.list_holding_sessions()
        return [self._result(session.id) for session in sessions]

    def reconcile(
        self,
        session_id: int,
        event_id: str,
        present_tags: set[str] | None = None,
        source: str = "hardware",
        occurred_at: datetime | None = None,
    ) -> CheckoutOut:
        """Compara os tablets esperados com os detectados.

        Detectados -> devolvidos. Ausentes -> continuam pendentes e geram divergência.
        Pode ser repetida para a mesma solicitação (com outro event_id) até fechar tudo.
        """
        try:
            return self._reconcile(session_id, event_id, present_tags, source, occurred_at)
        except ReaderError as exc:
            self._record_reader_error(session_id, str(exc))
            raise

    def _reconcile(
        self,
        session_id: int,
        event_id: str,
        present_tags: set[str] | None,
        source: str,
        occurred_at: datetime | None,
    ) -> CheckoutOut:
        with unit_of_work(self._db):
            session = self._checkouts.get_session(session_id, for_update=True)
            if session is None:
                raise SessionNotFoundError("Solicitação não encontrada.")
            if self._events.get_by_event_id(event_id) is not None:
                return self._result(session_id, duplicate=True)
            if session.status not in (SessionStatus.OPEN, SessionStatus.DIVERGENT):
                raise InvalidSessionStateError(
                    f"A solicitação está '{session.status}'; não há tablets a devolver."
                )
            cabinet = self._cabinets.get_by_id(session.cabinet_id)
            tags = (
                present_tags
                if present_tags is not None
                else self._inventory.read_present_tags(cabinet.code)
            )
            now = utcnow()
            returned, pending = self._match_items(session.id, set(tags), now)
            unknown = len(set(tags)) - len(self._tablets.get_by_tags(tags))
            divergence = None
            if pending:
                session.status = SessionStatus.DIVERGENT
                divergence = f"Devolução incompleta: pendentes {', '.join(pending)}."
                self._events.record(
                    cabinet_id=cabinet.id,
                    type=EventType.RETURN_DIVERGENCE,
                    source="system",
                    session_id=session.id,
                    details={"pending": pending},
                )
            else:
                session.status = SessionStatus.COMPLETED
                session.completed_at = now
                self._events.record(
                    cabinet_id=cabinet.id,
                    type=EventType.RETURN_RECONCILED,
                    source="system",
                    session_id=session.id,
                )
            self._events.record(
                cabinet_id=cabinet.id,
                type=EventType.INVENTORY_AFTER_RETURN,
                source=source,
                session_id=session.id,
                event_id=event_id,
                occurred_at=occurred_at,
                details={
                    "returned": returned,
                    "pending": pending,
                    "unknown_tags": max(unknown, 0),
                },
            )
            return self._result(session_id, divergence=divergence)

    def _match_items(self, session_id: int, present: set[str], now: datetime):
        returned: list[str] = []
        pending: list[str] = []
        for item in self._checkouts.list_active_items(session_id):
            if item.tablet.rfid_tag_uid in present:
                item.status = ItemStatus.RETURNED
                item.returned_at = now
                item.tablet.status = TabletStatus.AVAILABLE
                returned.append(item.tablet.asset_code)
            else:
                pending.append(item.tablet.asset_code)
        self._db.flush()
        return returned, pending

    def _result(
        self, session_id: int, duplicate: bool = False, divergence: str | None = None
    ) -> CheckoutOut:
        session = self._checkouts.get_session_with_items(session_id)
        return build_checkout_out(session, duplicate, divergence)

    def _record_reader_error(self, session_id: int, message: str) -> None:
        with unit_of_work(self._db):
            session = self._checkouts.get_session(session_id)
            if session is None:
                return
            self._events.record(
                cabinet_id=session.cabinet_id,
                type=EventType.READER_ERROR,
                source="system",
                session_id=session_id,
                details={"message": message},
            )
