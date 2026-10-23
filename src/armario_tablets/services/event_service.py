import logging

from sqlalchemy.orm import Session

from armario_tablets.database.session import unit_of_work
from armario_tablets.exceptions import InvalidSessionStateError, SessionNotFoundError
from armario_tablets.models import DoorState
from armario_tablets.repositories.checkout_repository import CheckoutRepository
from armario_tablets.repositories.event_repository import EventRepository
from armario_tablets.schemas.event_schema import EventOut, EventType, HardwareEventIn
from armario_tablets.services.cabinet_service import CabinetService
from armario_tablets.services.checkout_service import CheckoutService
from armario_tablets.services.return_service import ReturnService
from armario_tablets.utils.validators import normalize_uid

logger = logging.getLogger(__name__)


class HardwareEventService:
    """Recebe eventos do controlador/leitor (HTTP ou, no futuro, MQTT) de forma idempotente."""

    def __init__(
        self,
        db: Session,
        cabinets: CabinetService,
        checkouts: CheckoutRepository,
        events: EventRepository,
        checkout_service: CheckoutService,
        return_service: ReturnService,
    ) -> None:
        self._db = db
        self._cabinets = cabinets
        self._checkouts = checkouts
        self._events = events
        self._checkout_service = checkout_service
        self._return_service = return_service

    def handle(self, event: HardwareEventIn) -> EventOut:
        self._cabinets.get_by_code(event.cabinet_code)  # valida que o armário existe
        if event.type == EventType.INVENTORY_AFTER_CHECKOUT:
            result = self._checkout_service.confirm_checkout(
                self._require_session(event),
                event.event_id,
                self._present_tags(event),
                occurred_at=event.occurred_at,
            )
            return self._out(event, result.duplicate_event, result.session_id, result.status)
        if event.type == EventType.INVENTORY_AFTER_RETURN:
            result = self._return_service.reconcile(
                self._require_session(event),
                event.event_id,
                self._present_tags(event),
                occurred_at=event.occurred_at,
            )
            return self._out(event, result.duplicate_event, result.session_id, result.status)
        return self._handle_simple_event(event)

    def _handle_simple_event(self, event: HardwareEventIn) -> EventOut:
        """Portas e erros: registra uma única vez; erros encerram a solicitação em andamento."""
        with unit_of_work(self._db):
            cabinet = self._cabinets.get_by_code(event.cabinet_code, for_update=True)
            created = self._events.record(
                cabinet_id=cabinet.id,
                type=event.type,
                source="hardware",
                session_id=event.session_id,
                event_id=event.event_id,
                occurred_at=event.occurred_at,
                details=event.details,
            )
            if created:
                if event.type == EventType.DOOR_OPENED:
                    cabinet.door_state = DoorState.OPEN
                elif event.type == EventType.DOOR_CLOSED:
                    cabinet.door_state = DoorState.CLOSED
        if created and event.type in (EventType.LOCK_ERROR, EventType.READER_ERROR):
            self._fail_in_flight(event)
        return self._out(event, not created, event.session_id, None)

    def _fail_in_flight(self, event: HardwareEventIn) -> None:
        if event.session_id is None:
            return
        message = str(event.details.get("message", "erro informado pelo hardware"))
        self._checkout_service.mark_failed(event.session_id, event.type, message)

    @staticmethod
    def _require_session(event: HardwareEventIn) -> int:
        if event.session_id is None:
            raise SessionNotFoundError("O evento de inventário precisa informar session_id.")
        return event.session_id

    @staticmethod
    def _present_tags(event: HardwareEventIn) -> set[str]:
        tags = event.details.get("present_tags")
        if not isinstance(tags, list):
            raise InvalidSessionStateError("details.present_tags deve ser uma lista de UIDs.")
        return {normalize_uid(str(tag)) for tag in tags}

    @staticmethod
    def _out(event: HardwareEventIn, duplicate: bool, session_id, session_status) -> EventOut:
        return EventOut(
            event_id=event.event_id,
            type=event.type,
            duplicate=duplicate,
            session_id=session_id,
            session_status=session_status,
        )
