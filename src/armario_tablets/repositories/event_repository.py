import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from armario_tablets.models import Event
from armario_tablets.utils.datetime_utils import utcnow


class EventRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_event_id(self, event_id: str) -> Event | None:
        return self._db.scalar(select(Event).where(Event.event_id == event_id))

    def try_add(self, event: Event) -> bool:
        """Grava o evento. Devolve False se o event_id já existia (evento repetido).

        Usa SAVEPOINT para que a corrida entre duas gravações iguais não derrube
        a transação inteira.
        """
        if self.get_by_event_id(event.event_id) is not None:
            return False
        try:
            with self._db.begin_nested():
                self._db.add(event)
        except IntegrityError:
            return False
        return True

    def record(
        self,
        *,
        cabinet_id: int,
        type: str,
        source: str,
        session_id: int | None = None,
        details: dict[str, Any] | None = None,
        event_id: str | None = None,
        occurred_at: datetime | None = None,
    ) -> bool:
        """Cria e grava um evento. Sem event_id, gera um novo (evento interno)."""
        now = utcnow()
        event = Event(
            event_id=event_id or uuid.uuid4().hex,
            cabinet_id=cabinet_id,
            session_id=session_id,
            type=str(type),
            source=source,
            occurred_at=occurred_at or now,
            received_at=now,
            details=details or {},
        )
        return self.try_add(event)

    def list_by_session(self, session_id: int) -> list[Event]:
        query = select(Event).where(Event.session_id == session_id).order_by(Event.occurred_at)
        return list(self._db.scalars(query))
