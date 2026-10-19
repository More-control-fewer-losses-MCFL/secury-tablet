from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from armario_tablets.database.base import Base, JSONType
from armario_tablets.utils.datetime_utils import utcnow


class Event(Base):
    """Registro imutável de tudo que aconteceu (hardware, regras de negócio, erros)."""

    __tablename__ = "events"
    __table_args__ = (
        Index("ix_events_occurred_at", "occurred_at"),
        Index("ix_events_session_id", "session_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    # Chave de idempotência: o mesmo event_id nunca é processado duas vezes.
    event_id: Mapped[str] = mapped_column(String(64), unique=True)
    cabinet_id: Mapped[int] = mapped_column(ForeignKey("cabinets.id"))
    session_id: Mapped[int | None] = mapped_column(ForeignKey("checkout_sessions.id"))
    type: Mapped[str] = mapped_column(String(40))
    source: Mapped[str] = mapped_column(String(30))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    details: Mapped[dict[str, Any]] = mapped_column(JSONType, default=dict)
