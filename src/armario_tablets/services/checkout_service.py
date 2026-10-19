import logging
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from armario_tablets.database.session import unit_of_work
from armario_tablets.exceptions import (
    CabinetBusyError,
    InsufficientAvailabilityError,
    InvalidSessionStateError,
    LockError,
    ReaderError,
    SessionNotFoundError,
)
from armario_tablets.models import (
    IN_FLIGHT_STATUSES,
    Cabinet,
    CheckoutItem,
    CheckoutSession,
    ItemStatus,
    LockState,
    SessionStatus,
    TabletStatus,
)
from armario_tablets.repositories.checkout_repository import CheckoutRepository
from armario_tablets.repositories.event_repository import EventRepository
from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.schemas.checkout_schema import CheckoutItemOut, CheckoutOut
from armario_tablets.schemas.event_schema import EventType
from armario_tablets.services.badge_service import BadgeService
from armario_tablets.services.cabinet_service import CabinetService
from armario_tablets.services.inventory_service import InventoryService
from armario_tablets.utils.datetime_utils import ensure_utc, utcnow

logger = logging.getLogger(__name__)


def build_checkout_out(
    session: CheckoutSession, duplicate: bool = False, divergence: str | None = None
) -> CheckoutOut:
    items = [
        CheckoutItemOut(
            asset_code=item.tablet.asset_code,
            status=item.status,
            checked_out_at=item.checked_out_at,
            returned_at=item.returned_at,
        )
        for item in session.items
    ]
    pending = sum(1 for item in items if item.status == ItemStatus.ACTIVE)
    return CheckoutOut(
        session_id=session.id,
        status=session.status,
        professor_name=session.professor.name,
        requested_quantity=session.requested_quantity,
        taken_quantity=len(items),
        pending_quantity=pending,
        items=items,
        duplicate_event=duplicate,
        divergence=divergence,
    )


class CheckoutService:
    """Solicitação, destravamento e confirmação da retirada de tablets."""

    def __init__(
        self,
        db: Session,
        badges: BadgeService,
        cabinets: CabinetService,
        checkouts: CheckoutRepository,
        tablets: TabletRepository,
        events: EventRepository,
        inventory: InventoryService,
        reservation_ttl_minutes: int = 10,
    ) -> None:
        self._db = db
        self._badges = badges
        self._cabinets = cabinets
        self._checkouts = checkouts
        self._tablets = tablets
        self._events = events
        self._inventory = inventory
        self._ttl = timedelta(minutes=reservation_ttl_minutes)

    # ---------- 1) Solicitação e destravamento ----------

    def request_checkout(
        self,
        badge_uid: str,
        quantity: int,
        purpose: str,
        class_name: str | None,
        cabinet_code: str,
    ) -> CheckoutOut:
        """Valida professor e disponibilidade, cria a solicitação e destrava o armário.

        A quantidade pedida só reserva a vez no armário; os tablets só são marcados
        como retirados em `confirm_checkout`, depois da leitura do inventário.
        """
        session_id = self._create_pending_session(
            badge_uid, quantity, purpose, class_name, cabinet_code
        )
        self._unlock_and_confirm(session_id, cabinet_code)
        return self.get_result(session_id)

    def _create_pending_session(
        self, badge_uid: str, quantity: int, purpose: str, class_name: str | None, code: str
    ) -> int:
        with unit_of_work(self._db):
            professor = self._badges.identify(badge_uid)
            # Trava o armário: dois pedidos simultâneos são atendidos um de cada vez.
            cabinet = self._cabinets.get_by_code(code, for_update=True)
            if self._expire_stale_sessions(cabinet):
                raise CabinetBusyError("Já existe uma retirada em andamento neste armário.")
            available = self._tablets.count_available()
            if quantity > available:
                raise InsufficientAvailabilityError(
                    f"Solicitados {quantity}, mas só há {available} disponível(is)."
                )
            session = self._checkouts.add_session(
                CheckoutSession(
                    professor_id=professor.id,
                    cabinet_id=cabinet.id,
                    requested_quantity=quantity,
                    purpose=purpose,
                    class_name=class_name,
                    status=SessionStatus.PENDING,
                )
            )
            self._events.record(
                cabinet_id=cabinet.id,
                type=EventType.CHECKOUT_REQUESTED,
                source="system",
                session_id=session.id,
                details={"requested_quantity": quantity, "professor_id": professor.id},
            )
            return session.id

    def _expire_stale_sessions(self, cabinet: Cabinet) -> list[CheckoutSession]:
        """Cancela reservas antigas e devolve as que continuam em andamento."""
        cutoff = utcnow() - self._ttl
        remaining = []
        for session in self._checkouts.find_in_flight(cabinet.id):
            if ensure_utc(session.started_at) < cutoff:
                session.status = SessionStatus.CANCELLED
                session.completed_at = utcnow()
                self._events.record(
                    cabinet_id=cabinet.id,
                    type=EventType.SESSION_EXPIRED,
                    source="system",
                    session_id=session.id,
                )
            else:
                remaining.append(session)
        return remaining

    def _unlock_and_confirm(self, session_id: int, cabinet_code: str) -> None:
        try:
            self._cabinets.unlock_with_confirmation(cabinet_code)
        except LockError as exc:
            self._fail_session(session_id, EventType.LOCK_ERROR, str(exc))
            self._cabinets.relock(cabinet_code)
            raise
        with unit_of_work(self._db):
            session = self._get_session(session_id, for_update=True)
            session.status = SessionStatus.UNLOCKED
            cabinet = self._cabinets.get_by_id(session.cabinet_id)
            cabinet.lock_state = LockState.UNLOCKED
            self._events.record(
                cabinet_id=cabinet.id,
                type=EventType.UNLOCK_CONFIRMED,
                source="system",
                session_id=session_id,
            )

    # ---------- 2) Confirmação da retirada (leitura do inventário) ----------

    def confirm_checkout(
        self,
        session_id: int,
        event_id: str,
        present_tags: set[str] | None = None,
        source: str = "hardware",
        occurred_at: datetime | None = None,
    ) -> CheckoutOut:
        """Marca como retirados só os tablets cuja etiqueta sumiu do armário.

        `event_id` é a chave de idempotência: repetir o mesmo evento não gera
        uma segunda retirada. Sem `present_tags`, lê o inventário no leitor.
        """
        try:
            return self._confirm(session_id, event_id, present_tags, source, occurred_at)
        except ReaderError as exc:
            self._record_error(session_id, EventType.READER_ERROR, str(exc))
            raise

    def _confirm(
        self,
        session_id: int,
        event_id: str,
        present_tags: set[str] | None,
        source: str,
        occurred_at: datetime | None,
    ) -> CheckoutOut:
        with unit_of_work(self._db):
            session = self._get_session(session_id, for_update=True)
            if self._events.get_by_event_id(event_id) is not None:
                return self.get_result(session_id, duplicate=True)
            if session.status != SessionStatus.UNLOCKED:
                raise InvalidSessionStateError(
                    f"A solicitação está '{session.status}'; não aguarda confirmação de retirada."
                )
            cabinet = self._cabinets.get_by_id(session.cabinet_id)
            tags = (
                present_tags
                if present_tags is not None
                else self._inventory.read_present_tags(cabinet.code)
            )
            withdrawn = self._inventory.detect_withdrawn(set(tags))
            now = utcnow()
            for tablet in withdrawn:
                tablet.status = TabletStatus.CHECKED_OUT
                self._checkouts.add_item(
                    CheckoutItem(
                        session=session, tablet=tablet, checked_out_at=now, status=ItemStatus.ACTIVE
                    )
                )
            divergence = self._close_withdrawal(session, cabinet, len(withdrawn), now)
            self._events.record(
                cabinet_id=cabinet.id,
                type=EventType.INVENTORY_AFTER_CHECKOUT,
                source=source,
                session_id=session.id,
                event_id=event_id,
                occurred_at=occurred_at,
                details={
                    "requested": session.requested_quantity,
                    "taken": [t.asset_code for t in withdrawn],
                    "divergence": divergence,
                },
            )
            result = self.get_result(session_id, divergence=divergence)
            cabinet_code = cabinet.code
        self._cabinets.relock(cabinet_code)
        return result

    def _close_withdrawal(
        self, session: CheckoutSession, cabinet: Cabinet, taken: int, now: datetime
    ) -> str | None:
        cabinet.lock_state = LockState.LOCKED
        requested = session.requested_quantity
        if taken == 0:
            session.status = SessionStatus.CANCELLED
            session.completed_at = now
            self._record_system(cabinet, session, EventType.CHECKOUT_CANCELLED)
            return "Nenhum tablet foi retirado; solicitação cancelada."
        session.status = SessionStatus.OPEN
        self._record_system(cabinet, session, EventType.CHECKOUT_CONFIRMED, {"taken": taken})
        if taken < requested:
            self._record_system(cabinet, session, EventType.PARTIAL_WITHDRAWAL)
            return f"Retirada parcial: solicitados {requested}, retirados {taken}."
        if taken > requested:
            self._record_system(cabinet, session, EventType.EXTRA_WITHDRAWAL)
            return f"Retirados mais tablets do que o solicitado: {requested} pedidos, {taken}."
        return None

    # ---------- Falhas reportadas pelo hardware ----------

    def mark_failed(self, session_id: int, event_type: EventType, message: str) -> None:
        """Hardware informou erro de fechadura/leitor: encerra solicitações em andamento."""
        self._fail_session(session_id, event_type, message)

    def _fail_session(self, session_id: int, event_type: EventType, message: str) -> None:
        with unit_of_work(self._db):
            session = self._get_session(session_id, for_update=True)
            if session.status in IN_FLIGHT_STATUSES:
                session.status = SessionStatus.FAILED
                session.completed_at = utcnow()
                cabinet = self._cabinets.get_by_id(session.cabinet_id)
                cabinet.lock_state = LockState.UNKNOWN
            self._events.record(
                cabinet_id=session.cabinet_id,
                type=event_type,
                source="system",
                session_id=session_id,
                details={"message": message},
            )
        logger.error("Solicitação %s falhou: %s", session_id, event_type)

    def _record_error(self, session_id: int, event_type: EventType, message: str) -> None:
        """Registra o erro sem encerrar a solicitação (dá para tentar a leitura de novo)."""
        with unit_of_work(self._db):
            session = self._get_session(session_id)
            self._events.record(
                cabinet_id=session.cabinet_id,
                type=event_type,
                source="system",
                session_id=session_id,
                details={"message": message},
            )

    # ---------- Auxiliares ----------

    def get_result(
        self, session_id: int, duplicate: bool = False, divergence: str | None = None
    ) -> CheckoutOut:
        session = self._checkouts.get_session_with_items(session_id)
        if session is None:
            raise SessionNotFoundError("Solicitação não encontrada.")
        return build_checkout_out(session, duplicate, divergence)

    def _get_session(self, session_id: int, for_update: bool = False) -> CheckoutSession:
        session = self._checkouts.get_session(session_id, for_update=for_update)
        if session is None:
            raise SessionNotFoundError("Solicitação não encontrada.")
        return session

    def _record_system(
        self,
        cabinet: Cabinet,
        session: CheckoutSession,
        event_type: EventType,
        details: dict | None = None,
    ) -> None:
        self._events.record(
            cabinet_id=cabinet.id,
            type=event_type,
            source="system",
            session_id=session.id,
            details=details,
        )
